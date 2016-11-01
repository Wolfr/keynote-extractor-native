on CloseDocument()
    tell application "Keynote"
      if (count of documents <= 1)
        close the front document
        quit
      else
        close the front document
      end if
    end tell
end CloseDocument
