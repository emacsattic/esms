;;; esms-ssp-funs.el --- Send SMS messages directly from XEmacs
;;
;; $Id: esms-ssp-funs.el,v 1.1 2002/01/15 07:46:53 jarl Exp $
;;
;; $Id: esms-ssp-funs.el,v 1.1 2002/01/15 07:46:53 jarl Exp $
;; OriginalAuthor: Jarl Friis <jarl@diku.dk>
;; Maintainer: Jarl Friis <jarl@diku.dk>
;; Created: 12-09 , 2001
;; Last-Modified: <2001-12-13 11:10:45 CET (jarl)>
;; Version: see the variable esms-version
;; Homepage: http://emacs-sms.sf.net/
;; Keywords: SMS, elisp, eSMS
;;
;; Copyright (C) 2001 Jarl Friis
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;;; Commentary:
;; 

;;; Code:

;;; Here comes the code for opasia.dk
;;
;;

(defun esms--opasia.dk-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator
   'post
   "http://sms.opasia.dk/" ; url
   "http://sms.opasia.dk/" ; referer 
   (concat "action=send"
           "&to=" " DESTINATION "
           "&msg=" " MESSAGE "
           "&qmsg=V%E6lg+hurtig+besked+her..."
           "&from=" " SENDER "
           )

   `((" SENDER " . ,from)
     (" DESTINATION " . ,destination-number)
     (" MESSAGE " . ,message))
   ))

;;; Here comes the code for tiscali.dk
;;
;; verified  9/12 2001
(defun esms--tiscali.dk-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://www.tiscali.dk/services/sms.php4" ; url
   "http://www.tiscali.dk/services/sms.php4" ; referer
   (concat "sms_submit=1"
           "&sms_sender=" " SENDER "
           "&sms_recipient=" " DESTINATION "
           "&sms_message=" " MESSAGE "
           "&sms_charsLeft=" "10"
           "&x=12&y=11")
   `((" SENDER " . ,from)
     (" DESTINATION " . ,destination-number)
     (" MESSAGE " . ,message))
   ))

;;; Here comes the code for telebesked.dk
;;
;; verified  9/12 2001
(defun esms--telebesked.dk-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://www.telebesked.dk/sendsms.asp"; url
   "http://www.telebesked.dk/default2.asp" ; referer
   (concat "Nummer=" " DESTINATION "
           "&Afsender=" " SENDER "
           "&Besked=" " MESSAGE "
           "&JuleSMS="
           "&tilbage=" "10" ; chars-left
           )
   `((" SENDER " . ,from)
     (" DESTINATION " . ,destination-number)
     (" MESSAGE " . ,message))
   ))

;;; Here comes the code for telebesked.dk/no/
;;
;;
(defun esms--telebesked.dk/no-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://www.telebesked.dk/no/sendsms.asp" ; url
   "http://www.telebesked.dk/default2.asp" ; referer
   (concat "Nummer=" " DESTINATION "
           "&Afsender="   " SENDER "
           "&KvikBesked="
           "&Besked=" " MESSAGE "
           "&CharsLeft=" "10" ; chars-left
           )
   `((" SENDER " . ,from)
     (" DESTINATION " . ,destination-number)
     (" MESSAGE " . ,message))
   ))

;;; Here comes the code for uk.gsmbox.com/
;;
;;
(defun esms--uk.gsmbox.com-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://uk.gsmbox.com/freesms/preview.gsmbox" ; url
   "http://uk.gsmbox.com" ; referer
   (concat "messaggio=" " MESSAGE "
           "&pluto=pippo"
           "&prefisso=" " AREACODE "
           "&telefono=" " DESTINATION "
           "&SUBMIT=Send"
           )
   `((" MESSAGE " . ,message)
     (" AREACODE " . ,area-code)
     (" DESTINATION " . ,destination-number))
   ))

(defun esms--uk.gsmbox.com-request2 (buffer country-code area-code destination-number message from)
  ""
  (goto-char (point-min buffer) buffer)
  (re-search-forward "<img height=1 width=1 src=\\(http://corporate\\.gsmbox\\.com/adv/accessday\\.gsmbox.*?\\)>" (point-max buffer) t 1 buffer)
  (esms--http-request-generator 
   'get
   (buffer-substring (match-beginning 1) (match-end 1) buffer) ; url
   "" ; referer
   "" ; content template
   nil ; substitute-alist
   )
  )

;;; Here comes the code for es.gsmbox.com/
;;
;;
(defun esms--es.gsmbox.com-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://es.gsmbox.com/freesms/preview.gsmbox" ; url
   "http://es.gsmbox.com/index.gsmbox?country=es" ; referer
   (concat "messaggio=" " MESSAGE "
           "&country=es"
           "&prefisso=" " AREACODE "
           "&telefono=" " DESTINATION "
           )
   `((" MESSAGE " . ,message)
     (" AREACODE " . ,area-code)
     (" DESTINATION " . ,destination-number))
   ))

(defun esms--es.gsmbox.com-request2 (buffer country-code area-code destination-number message from)
  ""
  (save-excursion
    (let (form-start form-end messaggio telefono prefisso country secret-name secret-value)
      (and
       (goto-char (point-min buffer) buffer)
       (re-search-forward "<form action=conf_invio\\.gsmbox method=POST name=form" (point-max buffer) t 1 buffer)
       (setq form-start (match-beginning 0))
       (re-search-forward "</form>" (point-max buffer) t 1 buffer)
       (setq form-end (match-beginning 0))
       (goto-char form-start buffer)
       (re-search-forward "<input type=hidden name=messaggio value=\"\\(.*?\\)\">" form-end t 1 buffer)
       (setq messaggio (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=telefono value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq telefono (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=prefisso value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq prefisso (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=country value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq country (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=\"\\(.*?\\)\" value=\"\\(.*?\\)\">" form-end t 1 buffer)
       (setq secret-name (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (setq secret-value (buffer-substring (match-beginning 2) (match-end 2) buffer))
       ;; todo return the url, but ... it is a POST request, so how do I work around that?
       (esms--http-request-generator 
        'post
        "http://es.gsmbox.com/freesms/conf_invio.gsmbox" ; url
        "http://es.gsmbox.com/freesms/preview.gsmbox" ; referer
        (concat "imageField3.x=24&imageField3.y=9"
                "messaggio=" messaggio
                "&telefono=" telefono
                "&prefisso=" prefisso
                "&country=" country
                "&" secret-name "=" secret-value
                )
        nil ;; substitute alist
        )
       )))
  )

;;; Here comes the code for it.gsmbox.com/
;;
;;
(defun esms--it.gsmbox.com-request (buffer country-code area-code destination-number message from)
  ;;should maybe be a macro or defsubst so inline-susbtitution is done
  (esms--http-request-generator 
   'post
   "http://it.gsmbox.com/freesms/preview.gsmbox" ; url
   "http://it.gsmbox.com" ; referer
   (concat "messaggio=" " MESSAGE "
           "&country=it"
           "&prefisso=" " AREACODE "
           "&telefono=" " DESTINATION "
           )
   `((" MESSAGE " . ,message)
     (" AREACODE " . ,area-code)
     (" DESTINATION " . ,destination-number))
   ))


(defun esms--it.gsmbox.com-request2 (buffer country-code area-code destination-number message from)
  ""
  (save-excursion
    (let (form-start form-end messaggio telefono prefisso country secret-name secret-value)
      (and
       (goto-char (point-min buffer) buffer)
       (re-search-forward "<form action=conf_invio\\.gsmbox method=POST name=form" (point-max buffer) t 1 buffer)
       (setq form-start (match-beginning 0))
       (re-search-forward "</form>" (point-max buffer) t 1 buffer)
       (setq form-end (match-beginning 0))
       (goto-char form-start buffer)
       (re-search-forward "<input type=hidden name=messaggio value=\"\\(.*?\\)\">" form-end t 1 buffer)
       (setq messaggio (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=telefono value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq telefono (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=prefisso value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq prefisso (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=country value='\\(.*?\\)'>" form-end t 1 buffer)
       (setq country (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (re-search-forward "<input type=hidden name=\"\\(.*?\\)\" value=\"\\(.*?\\)\">" form-end t 1 buffer)
       (setq secret-name (buffer-substring (match-beginning 1) (match-end 1) buffer))
       (setq secret-value (buffer-substring (match-beginning 2) (match-end 2) buffer))
       ;; todo return the url, but ... it is a POST request, so how do I work around that?
       (esms--http-request-generator 
        'post
        "http://it.gsmbox.com/freesms/conf_invio.gsmbox" ; url
        "http://it.gsmbox.com/freesms/preview.gsmbox" ; referer
        (concat "imageField3.x=24&imageField3.y=9"
                "&sponsor_id=0"
                "messaggio=" messaggio
                "&telefono=" telefono
                "&prefisso=" prefisso
                "&country=" country
                "&" secret-name "=" secret-value
                )
        nil ;; substitute alist
        )
       )))
  )

;;; Here comes the code for sms.de
;;
;; TODO: this code is not yet complete, hence no adding to available SSPs
(defun esms--sms.de-request-func (country-code area-code destination-number message from)
  "Request function for sms.de.

TOD: This function is not yet fully compatible, messages will not be sent.

This SSP is quite special, it seems that you can send to anywhere in the world.

DESTINATION-NUMBER is a number, namely the phone number to send to.

MESSAGE is a string to send as SMS.

FROM is a string represeniting the sender."

;;algorithm:
;; Part1: send "GET / HTTP/1.1" to receive cookie-hostname
;;       fetch unique cookie id from host-name
;; Part2: return a POST request based on cookie

  (let* (
         ;;just when developing:
         (esms-user-agent "Mozilla/4.0 (compatible; MSIE 5.0; Windows) Opera 5.0  [en]")
         (http-response-buffer (generate-new-buffer "*sms-http-response*"))
         (host nil)
	 (port 80)
         cookie-host
         cookie-name
         success
         sms--http-connection
         (free-length (- 160
                         (if (> (length from) 0) 2 0);;eSMS will add a "<from>: "
                         (length from)))
         (message-length (length message))
         (chars-left (- free-length
                        message-length))
         (destination (if (numberp destination-number) (number-to-string destination-number) destination-number))
         (GSM-http-network (esms--http-translate " +45"))
         (intl-http-number (concat "%2B45" destination))
         (http-message (replace-in-string (replace-in-string (replace-in-string (replace-in-string
                                                                                 (concat message (esms--advertisement chars-left))
                                                                                 "\n" "%0A%0D") "&" "%26") "+" "%2B") " " "+"))
         (http-from (replace-in-string (replace-in-string (replace-in-string from "&" "%26") "+" "%2B") " " "+"))
         content
         )
    (unwind-protect
        (if (< chars-left 0)
            (error "Message must not exceed %s, yours is %s" free-length message-length)
          nil)
      (if esms-proxyhost
          (setq host esms-proxyhost
                port esms-proxyport)
        (setq host "www.sms.de"
              port 80)
        )
      
      ;;Part one: get cookie-hostname:
      (if nil ;; esms--debug
          (setq cookie-name "e73a00a53c58d70b5b701ecbdbec4d37"
                cookie-host (concat "www-" cookie-name ".id.sms.de"))
        ;;else
        (setq sms--http-connection (open-network-stream "sms--http-connection" http-response-buffer host port))
        (process-send-string sms--http-connection
                           (format "GET / HTTP/1.1
Connection: Keep-Alive
User-Agent: %s
Accept: text/*;q=1.0, image/png;q=1.0, image/jpeg;q=1.0, image/gif;q=1.0, image/*;q=0.8, */*;q=0.5
Accept-Encoding: x-gzip; q=1.0, gzip; q=1.0, identity
Accept-Charset: iso-8859-1;q=1.0, *;q=0.9, utf-8;q=0.8
Host: www.sms.de

" esms-user-agent ))
        ;;Wait for all data:
        ;;consider filter-functions, accept-process-output, process-sentinels
        ;;makes sure that we get it all:
        (accept-process-output sms--http-connection 0 100)
        (while (eq (process-status sms--http-connection) 'open)
          (accept-process-output sms--http-connection 1 0)
          )
        (goto-char (point-min http-response-buffer) http-response-buffer)
      ;; check for new host name: "Host: "
        ;; example : "Host: www-9a87640f0775719003a5a7802b591514.id.sms.de"
        (setq success (re-search-forward "^Location: *http://\\(www-\\(.*?\\)\.id\.sms\.de.*?\\)/" (point-max http-response-buffer) t 1 http-response-buffer))
        ;;      (goto-char (point-min http-response-buffer) http-response-buffer);;shouldn't be necessary
        (unless success
          (error "The service www.sms.de Failed!, see the log and %s" http-response-buffer))
        (setq cookie-host (buffer-substring (match-beginning 1) (match-end 1) http-response-buffer)
              cookie-name (buffer-substring (match-beginning 2) (match-end 2) http-response-buffer))
        (esms--log "Got host = %s, cookie = %s" cookie-host cookie-name)
        (esms--log "See result in %s" http-response-buffer)
        ;;        (kill-buffer http-response-buffer)
        )
      )
    ;;part 2:
    (setq content (concat
                   cookie-name "=" cookie-name
                   "&addyval=%5C%22%5C%22"
                   "&networkkey=+" GSM-http-network
                   "target_phone="intl-http-number
                   "&msg=" from (esms--http-translate ": ") http-message
                   "&smiley=&footerlenght=113&class=none&submitsms=sms+versenden"
                   ))
    ;;TODO: the referer seem to have something to do with GSM-network
    (concat
     "POST /sms/sms_send.php3 HTTP/1.1
Connection: Keep-Alive
User-Agent: " esms-user-agent "
Referer: http://www-" cookie-name ".id.sms.de:80/sms/sms_senden.php3?p=%20+45
Pragma: no-cache
Cache-control: no-cache
Accept: text/*;q=1.0, image/png;q=1.0, image/jpeg;q=1.0, image/gif;q=1.0, image/*;q=0.8, */*;q=0.5
Accept-Encoding: x-gzip; q=1.0, gzip; q=1.0, identity
Accept-Charset: iso-8859-1;q=1.0, *;q=0.9, utf-8;q=0.8
Host: www-" cookie-name ".id.sms.de
Cookie: " cookie-name "=" cookie-name "; C_SESSION_ID=" cookie-name "
Content-Type: application/x-www-form-urlencoded
Content-Length: " (number-to-string (length content)) "

" content "

")
    ))

(provide 'esms-ssp-funs)

;;; esms-ssp-funs.el ends here

;Local Variables:
;time-stamp-start: "Last-Modified:[ 	]+\\\\?[\"<]+"
;time-stamp-end: "\\\\?[\">]"
;time-stamp-line-limit: 10
;time-stamp-format: "%4y-%02m-%02d %02H:%02M:%02S %:Z (%u)"
;End: 

