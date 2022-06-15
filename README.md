# HEBREW SBV SUBTITLES FIXER
Some softwares such as VLC does not show Hebrew subtitles (and any other right-to-left written languages) in the correct format.
This script will fix this issue with the given sbv-formatted files.

For example: `"שלום!"` will be shown as `"!שלום"` in VLC.
(the exclamation mark is at the beginning!!)
The following script will fix this issue.

The actual function that does the fixing is `Subtitle.fixLine(:)`.
You may change the characters that are used to fix the line in the function.

# HOW TO RUN SCRIPT
You may run the script in Visual Studio Code, or any other IDE
that supports Swift.

# HOW TO RUN OVER FOLDERS
Use Running.run(atFolder:exportPath:) to run the script over a folder.
It will run over all of the files in the folder and in every sub-folder,
and export the files to the provided export path.

# SUPPORTED SUBTITLES FORMATS
Only `.sbv` format is supported at the moment.
Do not try to run on any other format.

# LICENCE
This script is licensed under the Attribution 3.0 Unported (CC BY 3.0) license.
For more information see https://creativecommons.org/licenses/by/3.0/
