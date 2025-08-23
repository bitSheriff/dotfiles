;nyquist plug-in
;version 4
;type tool
;codetype lisp
;name "Labels to Chapters"
;author "Steve Daulton"
;release 2.3.2
;copyright "Released under terms of the GNU General Public License version 2"

;control timebase "Time base" int "" 1000 100 2000
;control title "Title" string "" ""
;control encodedby "Encoded by" string "" ""
;control artist "Artist" string "" ""
;control date "Date" string "" "2020"
;control filename "Save file as" file "" "*default*/metadata.txt" "Text file|*.txt;*.TXT|All files|*.*;*" "save,overwrite"


(setf metadata
  (format nil ";FFMETADATA1~%~
              title=~a~%~
              encoded_by=~a~%~
              artist=~a~%~
              date=~a~%~
              encoder=Lavf58.27.103~%"
              title
              encodedby
              artist
              date))

;;  Get label data from first label track
(setf labels (second (first (aud-get-info "Labels"))))


(dolist (label labels)
  (setf chapter
    (format nil "[CHAPTER]~%~
                TIMEBASE=1/~a~%~
                START=~a~%~
                END=~a~%~
                title=~a~%"
                timebase
                (round (* timebase (first label)))
                (round (* timebase (second label)))
                (third label)))
  (string-append metadata chapter))


(setf fp (open filename :direction :output))
(format fp metadata)
(close fp)
(format nil "File written to~%~a" filename)
