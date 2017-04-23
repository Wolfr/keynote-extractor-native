on OpenDocument(presentationToExtract)
    tell application "Keynote"
        open presentationToExtract
        
        try
            if playing is true then tell the front document to stop

            # 1702: Corrupt data was detected.
            if not (exists document 1) then error number -1702

            on error errorMessage number errorNumber
#               display alert "EXPORT PROBLEM" message errorMessage

            # 10000: The Apple event handler failed.
            error number -10000
        end try
    end tell
end OpenDocument
