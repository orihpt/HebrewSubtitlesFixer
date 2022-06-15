
import Foundation

/*
----------------------------------------------------
HEBREW SBV SUBTITLES FIXER
Some softwares such as VLC does not show Hebrew subtitles
(and any other right-to-left written languages) 
in the correct format. This script will fix this issue.

For example: "שלום!" will be shown as "!שלום" in VLC.
(the exclamation mark is at the beginning!!)
The following script will fix this issue.

The actual function that does the fixing is Subtitle.fixLine(:).
You may change the characters that are used to fix the line in the function.

# HOW TO RUN SCRIPT
You may run the script in Visual Studio Code, or any other IDE
that supports Swift.

# HOW TO RUN OVER FOLDERS
Use Running.run(atFolder:exportPath:) to run the script over a folder.
It will run over all of the files in the folder and in every sub-folder,
and export the files to the provided export path.

# SUPPORTED SUBTITLES FORMATS
Only .sbv format is supported at the moment.
Do not try to run on any other format.

# LICENCE
This script is licensed under the Attribution 3.0 Unported (CC BY 3.0) license.
For more information see https://creativecommons.org/licenses/by/3.0/
----------------------------------------------------
*/

// Uncomment the next line to run the example:
Running.exampleFileTest(showResultVsExpected: true)

// Uncomment next lines to run over a folder:
/*
let inputFolder = "inputFolder"
let outputFolder = "outputFolder"
Running.run(atFolder: inputFolder, exportPath: outputFolder)
*/

class Running {
    // Runs over the given folder and exports the results to the given folder.
    static func run(atFolder folder: String, exportPath export: String) {
        try! FileManager.default.createDirectory(atPath: export, withIntermediateDirectories: true, attributes: nil)
        let fileManager = FileManager.default
        let files = try! fileManager.contentsOfDirectory(atPath: folder)
        for file in files where file != ".DS_Store" {
            let isDirectory = !file.contains(".")
            if isDirectory {
                print("Running at folder \(folder + "/" + file + "/")")
                run(atFolder: folder + "/" + file, exportPath: export + "/" + file)
            } else {
                print("Converting file \(folder + "/" + file)")
                convertAndSave(fromPath: folder + "/" + file, saveto: export + "/" + file)
            }
        }
    }

    // Given an example an input file (where subtitles are not shown correctly), runs it and compares the result to the expected output.
    static func exampleFileTest(showResultVsExpected: Bool = false) {
        let inPath = "input/original.sbv"
        let outPath  = "input/result.sbv"

        let output = try! readFromFile(path: outPath)
            .replacingOccurrences(of: "…", with: "...")

        let converted = convertFromPath(path: inPath)
        let ok = output == converted
        if ok {
            print("OK")
        } else {
            print("FAIL")
            if showResultVsExpected {
                let convertedLines = converted.components(separatedBy: "\n")
                let outputLines = output.components(separatedBy: "\n")
                let min = min(convertedLines.count, outputLines.count)
                for i in 0..<min {
                    let convertedLine = convertedLines[i]
                    let outputLine = outputLines[i]
                    if convertedLine != outputLine {
                        print("----- \(i) -----")
                        print("converted:\n\(convertedLine)")
                        print("original:\n\(outputLine)")
                    }
                }
                
                if convertedLines.count > outputLines.count {
                    print("\(convertedLines.count - outputLines.count) lines more in converted:")
                    for i in min..<convertedLines.count {
                        print("\(i): \(convertedLines[i])")
                    }
                } else if outputLines.count > convertedLines.count {
                    print("\(outputLines.count - convertedLines.count) lines more in output:")
                    for i in min..<outputLines.count {
                        print("\(i): \(outputLines[i])")
                    }
                }
            }
        }
    }
}

class Subtitle {
    var startEndStr: String
    var text: String
    
    init(startEndStr: String, text: String) {
        self.startEndStr = startEndStr
        self.text = text
    }

    init(component: String) {
        // First line
        self.startEndStr = component.components(separatedBy: "\n")[0]
        // line 2 and more
        self.text = component.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
    }

    // Fixing the text by inserting the characters at the end to the beginning and the beginning to the end.
    func fixText() {
        let lines = text.components(separatedBy: "\n").map { line in
            fixLine(line)
        }
        self.text = lines.joined(separator: "\n")
    }

    // Fixes the provided line.
    private func fixLine(_ line: String) -> String {
        guard line.count > 0 else {
            return ""
        }
        let charsSet = "\"!,.-?:;'״…"
        let chars = Array(charsSet)
        let trimmed = line.trimmingCharacters(in: CharacterSet(charactersIn: charsSet))

        // First
        var first = ""
        let lastIndex = text.count - 1
        var i = 0
        var flag = false
        while (i < lastIndex && !flag) {
            let c = line[line.index(line.startIndex, offsetBy: i)]
            if chars.contains(c) {
                first += String(c)
                i += 1
              } else {
                flag = true
            }
        }

        if (i == lastIndex) {
            return line
        }

        // Last
        var last = ""
        var j = 1
        flag = false
        while (j < lastIndex && !flag) {
            let c = line[line.index(line.endIndex, offsetBy: -j)]
            if chars.contains(c) {
                last += String(c)
                j += 1
            } else {
                flag = true
            }
        }

        return last + trimmed + first
    }

    // Imports subtitles from sbv file.
    static func fromSbv(_ str: String) -> [Subtitle] {
        let components = str.components(separatedBy: "\r\n\r\n")
        return components.map { Subtitle(component: $0) }
    }

    // Export subtitles in sbv format.
    static func sbv(_ subtitles: [Subtitle]) -> String {
        var str = ""
        for subtitle in subtitles {
            str += subtitle.startEndStr + "\n"
            str += subtitle.text + "\n\n"
        }
        str.removeLast(2)
        return str
    }
}

// Fix the provided subtitles file and returs the outputs. 
func convert(input: String) -> String {
    let subtitles = Subtitle.fromSbv(input)
    subtitles.forEach { $0.fixText() }
    return Subtitle.sbv(subtitles)
}

// Fix from subtitles file path and returns the result.
func convertFromPath(path: String) -> String {
    let input = try! readFromFile(path: path)
        .replacingOccurrences(of: "…", with: "...")
    return convert(input: input)
}

// Fix from subtitle file path and saves the result at the given path.
func convertAndSave(fromPath path: String, saveto savePath: String) {
    let result = convertFromPath(path: path)
    try! result.write(toFile: savePath, atomically: true, encoding: String.Encoding.utf8)
}

// Reads the file at the given path and returns the content.
// The following text
func readFromFile(path: String) throws -> String {
    do {
        switch path {
            case "input/original.sbv":
                return """
0:00:02.367,0:00:03.830
אנחנו אבני הקריסטל.

0:00:05.065,0:00:06.218
גארנט!

0:00:07.082,0:00:08.600
אמטיסט!

0:00:09.395,0:00:10.210
פרל!

0:00:12.130,0:00:13.661
וסטיבן!!

0:00:16.144,0:00:19.098
"סטיבן יוניברס" המלך

0:00:33.001,0:00:33.867
חזרתן.

0:00:34.167,0:00:35.467
היי סטיבן, תראה את זה!

0:00:37.096,0:00:37.776
וואו…!

0:00:37.867,0:00:39.096
מה את משוגעת?!

0:00:40.835,0:00:42.167
מה לעזאזל זה היה?!

0:00:42.267,0:00:45.520
גולגולת חשמלית, ארמון
הקריסטל שלנו היה מוצף בהן.

0:00:45.617,0:00:47.100
הן חיפשו את זה.

0:00:48.375,0:00:49.534
אפשר לראות את זה?

0:00:49.634,0:00:50.467
כן, ברור.

0:00:50.634,0:00:54.000
לא! הוא עוצמתי מאוד, לא היינו
צריכות אפילו להביא אותו הביתה.

0:00:54.468,0:00:56.634
גארנט, תגידי לפרל לתת לי לראות את הדבר!

0:00:57.000,0:00:58.306
ששש...

0:00:58.634,0:01:01.123
אוף באמת, אני רוצה לבוא בפעם הבאה.

0:01:01.197,0:01:03.400
אפילו כתבתי לנו שיר! הוא כזה-

0:01:03.494,0:01:05.409
אם אתה... שניה, חכו רגע.

0:01:08.334,0:01:11.028
אם אתה רשע ואתה עולה,

0:01:11.147,0:01:14.500
תוכל לסמוך על ארבעתנו שנפיל אותך

0:01:14.577,0:01:16.967
כי אנחנו טובים והרשע לעולם לא מנצח אותנו,

0:01:17.118,0:01:20.100
ננצח בקרב ואז נצא לאכול פיצות!

0:01:20.267,0:01:21.628
אנחנו,

0:01:21.797,0:01:23.600
אבני הקריסטל

0:01:24.268,0:01:27.000
תמיד נציל את היום,

0:01:27.409,0:01:29.409
ואם אתם חושבים שלא נוכל

0:01:30.267,0:01:32.513
תמיד נמצא דרך!

0:01:32.892,0:01:37.263
לכן האנשים של העולם הזה

0:01:37.427,0:01:39.068
מאמינים ב...

0:01:39.169,0:01:41.260
גארנט, אמטיסט, ו...

0:01:41.834,0:01:42.367
פרל,

0:01:42.467,0:01:44.267
וסטיבן!

0:01:48.134,0:01:50.030
"מה זה הקטע עם הפיצות"

"""
            case "input/result.sbv":
                return """
0:00:02.367,0:00:03.830
.אנחנו אבני הקריסטל

0:00:05.065,0:00:06.218
!גארנט

0:00:07.082,0:00:08.600
!אמטיסט

0:00:09.395,0:00:10.210
!פרל

0:00:12.130,0:00:13.661
!!וסטיבן

0:00:16.144,0:00:19.098
סטיבן יוניברס" המלך"

0:00:33.001,0:00:33.867
.חזרתן

0:00:34.167,0:00:35.467
!היי סטיבן, תראה את זה

0:00:37.096,0:00:37.776
!...וואו

0:00:37.867,0:00:39.096
!?מה את משוגעת

0:00:40.835,0:00:42.167
!?מה לעזאזל זה היה

0:00:42.267,0:00:45.520
גולגולת חשמלית, ארמון
.הקריסטל שלנו היה מוצף בהן

0:00:45.617,0:00:47.100
.הן חיפשו את זה

0:00:48.375,0:00:49.534
?אפשר לראות את זה

0:00:49.634,0:00:50.467
.כן, ברור

0:00:50.634,0:00:54.000
לא! הוא עוצמתי מאוד, לא היינו
.צריכות אפילו להביא אותו הביתה

0:00:54.468,0:00:56.634
!גארנט, תגידי לפרל לתת לי לראות את הדבר

0:00:57.000,0:00:58.306
...ששש

0:00:58.634,0:01:01.123
.אוף באמת, אני רוצה לבוא בפעם הבאה

0:01:01.197,0:01:03.400
-אפילו כתבתי לנו שיר! הוא כזה

0:01:03.494,0:01:05.409
.אם אתה... שניה, חכו רגע

0:01:08.334,0:01:11.028
,אם אתה רשע ואתה עולה

0:01:11.147,0:01:14.500
תוכל לסמוך על ארבעתנו שנפיל אותך

0:01:14.577,0:01:16.967
,כי אנחנו טובים והרשע לעולם לא מנצח אותנו

0:01:17.118,0:01:20.100
!ננצח בקרב ואז נצא לאכול פיצות

0:01:20.267,0:01:21.628
,אנחנו

0:01:21.797,0:01:23.600
אבני הקריסטל

0:01:24.268,0:01:27.000
,תמיד נציל את היום

0:01:27.409,0:01:29.409
ואם אתם חושבים שלא נוכל

0:01:30.267,0:01:32.513
!תמיד נמצא דרך

0:01:32.892,0:01:37.263
לכן האנשים של העולם הזה

0:01:37.427,0:01:39.068
...מאמינים ב

0:01:39.169,0:01:41.260
...גארנט, אמטיסט, ו

0:01:41.834,0:01:42.367
,פרל

0:01:42.467,0:01:44.267
!וסטיבן

0:01:48.134,0:01:50.030
"מה זה הקטע עם הפיצות"

"""
            default:
                return try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        }
    } catch let err {
        throw err
    }
}
