;;; esms.el --- Send SMS messages directly from XEmacs
;;
;; $Id: esms.el,v 1.2 2002/01/15 08:28:03 jarl Exp $
;; OriginalAuthor: Jarl Friis <jarl@diku.dk>
;; Maintainer: Jarl Friis <jarl@diku.dk>
;; Created: 18/6 , 2001
;; Last-Modified: <2002-01-15 09:44:29 CET (jarl)>
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

;; Features:
;;
;; - Send SMS messages directly from XEmacs.
;; - Send SMS to multiple recipients.
;; - Send long SMS messages.

;;; Acronyms:
;; SSP: SMS Service Provider

;;; Todo:
;;

;; - make a variable esms-force-same-ssp, that, if set, forces a
;;   (long) messages to be sent with *one* SSP, i.e. not split among
;;   several SSP attempts. This may result in parts of message
;;   arriving several times via different SSPs, defaults to nil

;; 1 redesign SSP-site abstraction -- ONE function to send ONE SMS
;;   that returns nil if successful, GENERALISE to optinally (defaults
;;   to Refresh-meta-tag) take REGEX-pattern to find refresh-url...
;;   This will add the myorange.dk/besked to the available SSPs DONE,
;;   needs testing... have not yet evaluated the refresh branch.
;;
;; - split to multiple files, how are such loaded???, see eicq...
;;
;; - Make menus, customisation, GNU Emacs compatible... have a look at
;;   ispell, since that package support same menus for both emacsen
;;   versions
;;
;; - The http communication heuristic seem not too perfect
;; (tiscali.dk), wait for open, wait for some text, wait for all
;; text. What does http-header fields like keep-Alive: and Connection
;; mean?
;;
;; - Make logging customizable, maybe even level-sensitive, maybe even a whole elisp-package
;; - make error-safe, whatever that means
;; - Some phonebook facilities, maybe integrating with some other
;;   PIM-software, like eicq, planner, calender, VM, etc.
;; - make some nice gui, i.e. menus, paritally done, but what about eSMS-ads on/off
;; - Integrate with receiption of SMS, http://web.icq.com/sms
;; - http://www.icq.com/icq123/email_cell.html
;; - Have a look at http://www.sibolgatech.com/Product.htm
;; - Add more SSP, other than the danish ones
;;   have a look at http://www.worldxs.net/sms.html, a list of sites
;;               http://members.tripod.com/~marcoswede/smsfr.html
;;               http://esms.sourceforge.net
;; - automatically split messages longer than limit to multiple small messages (could be slightly improved, how???)
;;  - Check out splitting of the following on opasia:
;;   "Denne besked er lang så vi kan test længden af beskeder. Her er vi nået ca. halvvejs. nu begynder jeg snart at tælle ned... 130  !12345678901234567890"
;;   It doesn't seem to be correct

;; - multithreaded... Hangs while sending!, use sentinels, queing,
;;   remember to check queue when exiting XEmacs. Consider elib things like queues and cookies.
;;   Seems like a problem since XEmacs is not multithreaded!, figure out something new.

;; check out world portals like
;; www.sms.de
;; http://zekiller.skytech.org/smssend_en.html
;; http://www.linuxlinks.com/Software/Internet/Communications/SMS/
;; www.mtnsms.com
;; http://web.icq.com/sms

;;; Commentary:
;; 
;; use `tcpdump -s 4096 -w myorange.dk` while submiting a SMS via browser to hack'em


;;; Code:


(require 'esms-ssp-funs)
(require 'esms-conf)

(defgroup eSMS nil
  "Send SMS messages directly from XEmacs"
  :group 'applications
  ;;  :group 'comm ;alternatively
  )

(defconst esms-version "0.8.0beta3"
  "The version number of the eSMS package.")

(defconst esms-about-string
  (format
   
   "About eSMS:

Version  : %s
Author   : Jarl Friis <jarl@diku.dk>
Homepage : http://emacs-sms.sf.net/"
   esms-version)
  "The message in the about dialog.")

;; Use (assoc "http" url-proxy-services) instead
(defcustom esms-proxyhost nil
  
  "*Set this variable if you are behind firewall.
If you are behind a firewall, you need to set this variable to be
the name of the http-proxy.  If you are directly connected, just set it
to nil, which is also the default, if nil then the variable
`esms-proxyport' is ignored."

  :group 'eSMS
  ;;TODO: add some constraint function on the host string, use :match keyword
  :type '(string)
  )

(defcustom esms-proxyport 80

  "*Set this variable if you are behind firewall.  Set this variable to
the port of your http-proxy, default is 80, the value is ignored if
`esms-proxyhost' is set to nil."

  :group 'eSMS
  :type '(integer)
  )

(defcustom esms-default-country-code 45 

  "*Set this variable to your default country code.  Country code is
always used by eSMS."

  :group 'eSMS
  :type '(integer)
  )

(defcustom esms-default-area-code ""

  "*Set this variable to your default area code.  if the country does
not use area codes set it to the empty string."

  :group 'eSMS
  :type '(string)
  )

(defcustom esms-user-agent 
  (format "Emacs eSMS-package (esms.el) V %s" esms-version)
  "*The user agent string used in the HTTP header."

  :group 'eSMS
  :type '(string)
  )

;;uncomment the following if SSP becomes suspicious
;;(setq esms-user-agent "Mozilla/4.0 (compatible; MSIE 5.0; Linux 2.2.16 i686) Opera 5.0  [en]")

(defcustom esms-ssp-priority-list 
  '(opasia.dk 
    tiscali.dk 
    telebesked.dk 
    myorange.dk/besked 
    uk.gsmbox.com 
    es.gsmbox.com
    it.gsmbox.com)
  "*SSP priority list.

A list that represent the priority of prefered SMS Service Providers
(SSP).  The list must contain symbols from `esms--ssp-alist'"

  :group 'eSMS
  :type '(string)
  )

(defvar esms--ssp-alist nil
  "This is an alist.
The keys are SSP symbols, so the list has the
following structure:
  (SSP-SYMBOL NAME DESCRIPTION MESG-LENGTH-FUNC TRANSMIT-FUNC COUNTRY-LIST AREA-LIST), where

  SYMBOL is the key in this list and the one to be used in
ESMS-SSP-PRIORITY-LIST

  NAME is a string of the name of the SSP, this will show in the
GUI-menu

  DESCRIPTION A string that documents features regarding this SSP.

  MESG-LENGTH-FUNC a function that calculates length of message using
this SSP, taking two arguments from and optionally message, usefull
for calculating free length on an SSP: 160-result.

  TRANSMIT-FUNC is a function that sends *one* SMS, and assumes the
message can fit, arguments are country-code area-code phone-number,
message, from.

  COUNTRY-LIST is a list of country codes that the SSP support, t means any, nil means none.

  AREA-LIST is a list of area codes that the SSP support.  If no area
code is used set the list to contain only the empty string."

 )

(defvar esms-log-buffer-name "*eSMS-log*"
  "The name of the buffer to be used as logger, mostly for debugging."
  )

(defvar esms-log-buffer nil
  "The buffer to be used as logger, mostly for debugging."
  )

(defvar esms--debug nil
  "Set this if you want debug-buffers to stay."
  )

(defmacro esms--log (&rest args)

  "Log function.
Logs information in buffer with name
`esms-log-buffer-name', see also variable `esms-log-buffer'.  ARGS are
passed to format"

  (or (buffer-live-p esms-log-buffer)
      (setq esms-log-buffer (generate-new-buffer (generate-new-buffer-name esms-log-buffer-name esms-log-buffer-name)))
      )
  (with-current-buffer esms-log-buffer
    ;; TODO: save point-position
    (let ((log-text (eval (cons 'format args))))
      (goto-char (point-max esms-log-buffer) esms-log-buffer)
      (insert-string (format "%s > %s\n"
                             (format-time-string "%e/%m %Y %k:%M:%S" (current-time))
                             ;; (eval (cons 'format args))) esms-log-buffer)
                             log-text) esms-log-buffer)
      log-text;return the formated text
      )
    )
  )

(defun esms--http-translate (text)

  "Translate to http strings.

TEXT is the original text."

  (replace-in-string (replace-in-string (replace-in-string (replace-in-string text
                                                                              "\n" "%0A%0D") "&" "%26") "+" "%2B") " " "+")
  )

(defun esms--generic-message-length-func (fixed-text from-addition)
  "Return a function that calculates message length.

FIXED-TEXT is the string that represents the text (from SSP) that
always appears in SMS messages.

FROM-ADDITION is the text that will be added somewhere in the
resulting SMS when a from field is suplied."

  `(lambda (from &optional message)
    (let* ((fixed-text ,fixed-text);evaluate it to 'constant'
           (from-addition ,from-addition);evaluate it to 'constant'
           (message (or message ""))
           (from (or from ""))
           )
      (+ (length fixed-text)
         (if (> (length from) 0)
             (length from-addition)
           0)
         (length from)
         (length message)
         )
      )
    )
  )

(defun esms--generic-HTTP-chain-requester (request-func-list country-code area-code destination-number message from)
  "A generic function to make a sequence HTTP requests.

REQUEST-FUNC-LIST is a list of functions that returns a string with
the HTTP-request.  The parameters to those functions must be (BUFFER
COUNTRY-CODE AREA-CODE DESTINATION-NUMBER MESSAGE FROM). The return
must be a valid HTTP/1.1 request.

COUNTRY-CODE is the country code.

AREA-CODE is the area-code.

DESTINATION-NUMBER is the phone number to send to.

MESSAGE is a string to send as SMS.

FROM is a string represeniting the sender.

It calls the functions in REQUEST-FUNC-LIST sequentially, the response
from one request will be the BUFFER of the succesive call."

  ;; TODO, implement such that the first call will be given the
  ;; text-composer buffer as argument, why not.

  (let* ((http-buffer-list nil)
         (request-func nil)
         (success t)
         (request-number 0)
         (http-response-buffer nil); eventually put the message-compose buffer here.
         (http-request nil)
         (next-referer nil)
         http-connection 
         )
    (or (and esms--debug (esms--log "Making %d HTTP request(s)" (length request-func-list))) t)
    (while (and
            success
            (setq request-func (car request-func-list)))
      (setq http-buffer-list (cons http-response-buffer http-buffer-list))
      (or 
       (and 
        (setq http-request (funcall request-func http-response-buffer country-code area-code destination-number message from))
        (progn
          (setq http-request-buffer  (generate-new-buffer "*sms-http-request*"))
          (insert-string http-request http-request-buffer)
          (and next-referer
               (goto-char (point-min http-request-buffer) http-request-buffer)
               (re-search-forward "^Referer: \\(.*?\\)$" (point-max http-request-buffer) t 1 http-request-buffer)
               (replace-match (format "Referer: %s" next-referer))
               )
          (goto-char (point-min http-request-buffer) http-request-buffer)
          (re-search-forward "^\\(GET\\|POST\\) \\(http://\\([^/]*?\\)/.*?\\)[\t\n ?]" (point-max http-request-buffer) t 1 http-request-buffer)
          (setq next-referer (buffer-substring (match-beginning 2) (match-end 2) http-request-buffer)
                host (or esms-proxyhost (buffer-substring (match-beginning 3) (match-end 3) http-request-buffer))
                port (or (and esms-proxyhost esms-proxyport) 80))
          (kill-buffer http-request-buffer)
          (setq http-response-buffer (generate-new-buffer "*sms-http-response*")
                http-connection (open-network-stream "sms--http-connection" http-response-buffer host port))
          ;; (esms--log "DEBUG: process-status = %s." (process-status http-connection))
          (while (not (eq (process-status http-connection) 'open))
            (sit-for 0.1);;wait 100ms to open
            )
          (process-send-string http-connection http-request)
          ;; (esms--log "DEBUG: process-status = %s" (process-status http-connection))
          ;;
          ;; Wait for all data:
          ;; consider filter-functions, accept-process-output, process-sentinels
          ;; makes sure that we get it all:
          (accept-process-output http-connection 0 100)
          (while (eq (process-status http-connection) 'open)
            (accept-process-output http-connection 1 0)
            )
          t)
        (goto-char (point-min http-response-buffer) http-response-buffer)
        ;; check for HTTP OK: "HTTP/1.? 2?? OK"
        (setq success (re-search-forward "^HTTP/1.[0-2] [2-3][0-9][0-9]" (point-max http-response-buffer) t 1 http-response-buffer))
        (setq request-func-list (cdr request-func-list)
              request-number (1+ request-number)) 
        (or (and esms--debug (esms--log "HTTP Request %d success!" request-number)) t)
        )
       ;;failure (in one way or another)
       (if esms--debug
           (progn
             (setq http-debug-buffer (generate-new-buffer "*esms-http-chain-debug*"))
             (insert-string http-request http-debug-buffer)
             (insert-string "================================================================================\n" http-debug-buffer)
             (insert-string (buffer-string (point-min http-response-buffer)
                                           (point-max http-response-buffer)
                                           http-response-buffer)
                            http-debug-buffer)
             (esms--log "SMS Message to %s failed! try again later, the server may be down. See %s for debug-info."
                        destination-number
                        (buffer-name http-debug-buffer)
                        )
             )
         ;;else:
         (esms--log "HTTP Request %d failed! try again later, the server may be down." request-number)
         ))
      );while
    (setq http-buffer-list (reverse http-buffer-list))
    (if success
        (progn 
          ;; clean up buffers in http-buffer-list
          (esms--log "SMS Message to %s sent." destination-number)
          )
      ());if
    (not success) ; return value
    );let
  );defun


(defun esms--refresh-request (buffer country-code area-code destination-number message from)
  "Generates a HTTP GET request based on the non-HTTP compliant refresh meta-tag.

Search BUFFER for a meta-tag HTTP-EQUIV = \"REFRESH\" content =
\"sec\; URL\" and generates a HTTP request that loads that
URL. COUNTRY-CODE, AREA-CODE, DESTINATION-NUMBER, MESSAGE, FROM are
not used, but simply there to comply with the functions to be used
with `esms--generic-HTTP-chain-requester'."

  (and 
   (re-search-forward "[Hh][Tt][Tt][Pp]-[Ee][Qq][Uu][Ii][Vv] *?= *?\"[Rr][Ee][Ff][Rr][Ee][Ss][Hh]\" *[Cc][Oo][Nn][Tt][Ee][Nn][Tt] *?= *?\".*?;[Uu][Rr][Ll]=\\(http://[^/]*?/.*?\\)\"" (point-max buffer) t 1 buffer)
   (setq refresh-url (buffer-substring (match-beginning 1) (match-end 1) http-response-buffer))
   (esms--http-request-generator 'get refresh-url ""  "" nil)
   )
  )

;;;
;;
;; Seting up the SSP-alist.
;;

(defun esms--send-single-long-message (country-code area-code destination-number message from)
  "Send one long message to one phonenumber.

Splitting is done according SSP message length.  Uses
`esms-ssp-priority-list' as priority list.  It tries 3 times on each
SSP, then trying the next one.

COUNTRY-CODE is a number representing the country code of the destination.

AREA-CODE is a area-code part of the destination-number.

DESTINATION-NUMBER is a number, namely the phone number to send to.

MESSAGE is a string to send as SMS.

FROM is a string represeniting the sender."

  (let* ((ssp-list esms-ssp-priority-list)
         ssp-name
         ssp-length-fun
         ssp-transmit-fun
         ssp-country-list
         ssp-area-list
         ssp-useful
         (fail-count 0)
         fail-list
         message-list
         message-counter
         )
    (while (and fail-count ssp-list)
      (setq fail-count 0
            ssp-name         (nth 1 (assoc (car ssp-list) esms--ssp-alist))
            ssp-length-fun   (nth 3 (assoc (car ssp-list) esms--ssp-alist))
            ssp-transmit-fun (nth 4 (assoc (car ssp-list) esms--ssp-alist))
            ssp-country-alist (nth 5 (assoc (car ssp-list) esms--ssp-alist))
            message-list (esms--fit-message-to-size message (- 160 (funcall ssp-length-fun from "")) t t)
            ssp-useful
            (or (member area-code (cdr (assoc country-code ssp-country-alist)))
                (progn 
                  (esms--log "prefix %s-%s not supported by %s" country-code area-code ssp-name)
                  nil)
                )
            )
      (and 
       ssp-useful
       (or (and esms--debug (esms--log "Using %s to send to %s-%s-%s "
                                       (car ssp-list) country-code area-code destination-number)) t)
       (while (and fail-count (< fail-count 3));; 3 attempts on same SSP or success (nil)
         ;; ssp-transmit-fun must return nil on success
         (setq messages (length message-list)
               message-counter 1
               fail-list
               (mapcar (lambda (mes)
                         (message "Be patient, sending %s of %s to %s: '%S'"
                                  message-counter
                                  messages
                                  destination-number
                                  mes)
                         (setq message-counter (1+ message-counter))
                         (funcall ssp-transmit-fun (number-to-string country-code) area-code destination-number mes from) ; return value
                         )
                       message-list)
               fail-count (and (eval (cons 'or fail-list))
                               (1+ fail-count))
               )
         (if (null fail-count);;success
             (progn
               (message "SMS Message to %s sent!" destination-number)
               (esms--log "SMS Message to %s sent with %s."
                          destination-number
                          (car ssp-list))
               )
           (esms--log "Some messages were not sent: %s" fail-list)
           )
         ))
      (if fail-count
          (progn
            (esms--log "Giving up %s" (car ssp-list))
            (setq ssp-list (cdr ssp-list)) ; try next SSP
            (if ssp-list
                (esms--log "Trying %s instead." (car ssp-list))
              (esms--log "No more SSPs to try, giving up.")
              )
            )
        )
      )
    (if ssp-list
        (length message-list); return number of messages, hmmm... what about errors
      (esms--log "All SSPs failed, giving up." )
      (error "All SSPs failed, giving up")
      nil ; returns error
      )
    )
  )

(defun esms--fit-message-to-size (message size external-ads emacs-ads)
  "Split message to a list of messages of a given maximum size.

MESSAGE is a string to send as SMS.

SIZE is the maximum size of the resulting messages.

EXTERNAL-ADS If non-nil external advertisements will be avoided if
possible.

EMACS-ADS If non-nil eSMS ads will not be sent with it.

The splited messages will contain startsigns such as '(x/y)' and end
with elipses like '-->'"

  ;;TODO:
  ;; - if not external-ads, pad with space on last message.
  ;; -- It will bail out if a single word is larger than size...
  ;; - If nice splitting is done multiple spaces are ignored, so are newlines.
  ;; - make it customizable to choose among nice splitting (between
  ;;   words), and forced splitting (even in words)
  (let* ((continues-string "-->")       ; TODO: make it CUSTOMIZABLE
         (word-list (split-string message))
         (mes-word-list nil)            ; message word list
         (message-list-list nil)        ; List of message word lists
         (message-list nil)             ; the resulting one
         (k 1)
         (max-messages 99)
         (last-word-in-sentence (lambda (word--list)
                                  ;; returns t if it's last word in sentence.
                                  (let ((word1 (car  word--list))
                                        (word2 (cadr word--list))
                                        )
                                    (if (and (char-equal ?. (elt  word1 (1- (length word1))))
                                             (or (null word2) (char-equal (elt word2 0) (upcase (elt word2 0))))
                                             )
                                        t nil)))
                                )
         nmessages
         )
    (while word-list
      (setq mes-word-list (list (format "(%s/%s)\n" k max-messages))
            )
      (if (not (and word-list (<= (+
                                   (length (mapconcat 'identity mes-word-list " "))
                                   1 (length (car word-list)) ; length of (space plus) next word.
                                   1 (length continues-string) ; length of (space plus) "-->".
                                   ) size)
                    ))
          (error "Word is too long, workaround is not implemented") ; it will detect it, but not split it.
        ;;else take as many words as possible
        (while (and word-list (<= (+
                                   (length (mapconcat 'identity mes-word-list " "))
                                   1 (length (car word-list)) ; length of (space plus) next word.
                                   1 (length continues-string) ; length of (space plus) "-->".
                                   ) size))
          (if (> (length (car word-list)) 0)
              (setq mes-word-list (append mes-word-list (list (car word-list))))
            )
          (setq word-list (cdr word-list))
          )
        )
      (setq k (1+ k)
            message-list-list (append message-list-list (list (cdr mes-word-list))))
      )
    (setq k 1
          nmessages (length message-list-list))
    ;;The algorithm for inserting spaces:
    ;;Insert double spaces if its an end of sentence and there are space left.
    ;;   pad the rest to end of message before continues-string
    (mapcar (lambda (word--list)        ; a function that fills spaces in between list-elements
              (let* ((word--list (if (= 1 nmessages)
                                     word--list
                                   (cons (format "(%s/%s)\n" k nmessages) word--list)
                                   ))
                     (min-size (length (mapconcat 'identity (cons continues-string word--list) " ")))
                     (extra-spaces (- size min-size))
                     (body "")
                     )
                (while word--list
                  (setq body (concat body (car word--list)
                                     (if (and (> extra-spaces 0) (funcall last-word-in-sentence word--list))
                                         (progn
                                           (setq extra-spaces (- extra-spaces 1))
                                           "  "
                                           )
                                       " ")
                                     )
                        word--list (cdr word--list)
                        )
                  )
                (concat body
                        (if (= nmessages k) ; if last message
                            (progn  ; We don't even need to increase k.
                              (and emacs-ads (esms--advertisement extra-spaces)); add the ad
                              )
                          (setq k (1+ k))
                          (concat (make-string extra-spaces ?  ) continues-string))) ; else pad with spaces
                )
              )                         ; end of lambda-func
            message-list-list)          ; on message-list-list
    ))

;; Test-string:
;; The console for a PC Linux system is normally the computer monitor in text mode. It emulates a terminal of type 'Linux'. There is no way (unless you want to spend weeks rewriting the kernel code) to get it to emulate anything else.

;;Not all SSPs support mutiple spaces and/or newlines
(defun esms--send-longmessage-to-mutiple-numbers (number-list message from)
  "Sends length-fitted messages to all numbers in a given list.

NUMBER-LIST The list of triple-lists containing coutrny-code, area-code, phone number.

MESSAGE is a string to send as SMS.

FROM is a string represeniting the sender."

  (let* ((from (or from (getenv "USER")))
         (message-size-limit 500)       ; make it CUSTOMIZABLE
         ;;         (opasia.dk-size (- 138 (length from)))
         ;;         (tiscali.dk-size (- 142 (length from)))
         ;;         (myorange.dk-size (- 123 5 (length from)))
         ;;         (telebesked.dk-size (- 123 1  (length from)))
         ;;         (telebesked.dk-no-size (- 123 1 (length from)))
         (numbers (length number-list))
         message-count-list
         messages
         )
    (if (> (length message) message-size-limit)
        (error "Message is longer than %s, drop it" message-size-limit)
      (setq message-count-list (mapcar (lambda (number-triple)
                                         (esms--send-single-long-message (car number-triple) (cadr number-triple) (caddr number-triple) message from))
                                       number-list)
            messages (car message-count-list) ; TODO: just for now
            )
      (message "Sent %s message%s to %s number%s. A total of %s SMS-message%s."
               messages
               (if (> messages 1) "s" "")
               numbers
               (if (> numbers 1) "s" "")
               (* messages numbers)
               (if (> (* messages numbers) 1) "s" "")
               )
      )
    )
  )

(defun esms-add-ssp (symbol name description length-fun send-fun country-alist)

  "Add an SSP to the `esms--ssp-alist'.

SYMBOL is the symbol used for this ssp.

NAME is a string representing the SSP, shown in menu.

DESCRIPTION is a string describing the SSP, eventually a feature description.

LENGTH-FUN is a function to compute the length taking two argument: from message.

SEND-FUN is a function that will send one SMS to through this SSP.

COUNTRY-ALIST is an alist of country codes as keys and a list of area
codes as values

returns nil if everything went ok, returns an \"entry\" in
`esms--ssp-alist' if symbol is occupied."
  
  (or (assoc symbol esms--ssp-alist) 
      (let ((ssp-entry (list symbol 
                             name
                             description
                             length-fun
                             send-fun
                             country-alist
                             ))
            )
        (setq esms--ssp-alist
              (cons ssp-entry esms--ssp-alist))
        nil)
      )
  )

(esms--default-configuration); setup the default esms--ssp-alist

;;; Here comes the code for some testing SSPs
;;
;;
(if esms--debug
    (let*
        ((esms--test-length-func (esms--generic-message-length-func "REKLAME for test (From:) " " "))
         (esms--test-transmit-func
          '(lambda (country area number message from)
             (esms--log "TEST-SSP.DK:Sending '%S' to %s-%s-%s." message country area number)
             nil;;return success
             ))
         (esms--test-transmit-func-fail
          '(lambda (country area number message from)
             (esms--log "TEST-SSP.DK:Sending '%S' to %s-%s-%s failed!" message country area number)
             t;;return error
             ))
         )
      (esms-add-ssp
       'test-ssp
       "for testing only"
       "This SSP is only ment for test purposes."
       (esms--generic-message-length-func "TEST commercial " "From: ")
       esms--test-transmit-func-fail
       '(45)
       '("")
       )
      )
  )


(defun esms--http-request-generator (method url referer content-template substitute-alist)
  "generates a HTTP/1.1 complient request based on CONTETNT-TEMPLATE.

METHOD. if it is set to `get' the \"GET\" method is used otherwise \"POST\"

URL the URL to which the request should go.

CONTENT-TEMPLATE is a template of the content with tags (from
TAG-LIST) to insert the parameters.

TAG-ALIST is an alist of with template-tags as keys and
replace-text as values

Returns a string where the alist keys has been replaced by the
alist values, e.g. the list '((\" SENDER \" . \"me\") (\" MESSAGE \"
. \"hello world\"))"
  (let (
        (mylist substitute-alist)
        (content content-template)
        (host-name (replace-in-string url "^http://\\(.*?\\)/.*?$"  "\\1"))
        mypair
        )
    (while (setq mypair (car mylist))
      ;;could be optimised using a buffer
      (setq 
       content (replace-in-string content (car mypair) 
                                  (esms--http-translate (cdr mypair))
                                  t)
       mylist (cdr mylist))
      )
    (concat (or (and (equal method 'get) "GET") "POST") " "url " HTTP/1.1
Connection: Keep-Alive\nUser-Agent: " esms-user-agent "
Referer: " referer "
Pragma: no-cache
Cache-control: no-cache
Accept: text/*;q=1.0, image/png;q=1.0, image/jpeg;q=1.0, image/gif;q=1.0, image/*;q=0.8, */*;q=0.5
Accept-Encoding: x-gzip; q=1.0, gzip; q=1.0, identity
Accept-Charset: iso8859-1;q=1.0, *;q=0.9, utf-8;q=0.8
Accept-Language: da, en_GB, en
Host: " host-name "
Content-Type: application/x-www-form-urlencoded
"
"Content-length: " (number-to-string (length content))
"\n\n"
content
            "\n\n")
    
    )
  )


;;;-----------
;;;###autoload
(defun sms-send-message (numbers message &optional from)
  "Send an SMS message to multiple mobile phone recipients.

NUMBERS a string of multiple phonenumbers.

MESSAGE a string to send eventually as several SMS messages.

FROM is a string represeniting the sender.

Sends SMS message MESSAGE to the the mobile phone recipients given in
NUMBERS.  If the FROM is left blank, the value of USER environment
variable is used.  Several numbers can be entered separated by normal
separators, i.e.\ the pattern [;:, \f\t\n\r\v]+."

  (interactive "sEnter number(s):\nsEnter message:")
  
  (let ((make-number-triple 
         (lambda (str)
           (let* (country-string area-string destination-string)
             
             (or (string-match "^\\(\\(\\([0-9]+\\)-\\)?\\([0-9]*\\)-\\)?\\([0-9]+\\)$" str)
                 (error "cannot parse '%s' as a number-triple, format is [[c-]a-]n " str)
                 )
             (setq country-string     (or (and (match-beginning 3) (match-end 3)
                                               (string-to-number (substring str (match-beginning 3) (match-end 3))))
                                          esms-default-country-code)
                   area-string        (or (and (match-beginning 4) (match-end 4)
                                               (< (match-beginning 4) (match-end 4))
                                               (substring str (match-beginning 4) (match-end 4)))
                                          esms-default-area-code)
                   destination-string (or (and (match-beginning 5) (match-end 5)
                                               (substring str (match-beginning 5) (match-end 5)))
                                          (error "eSMS: Internal error")) ;this cannot happend
                   )
             (list country-string area-string destination-string)
             ))
         )
        )
    (esms--send-longmessage-to-mutiple-numbers (mapcar make-number-triple (split-string numbers "[;:, \f\t\n\r\v]+")) message from)
    )
  )

(defun esms--advertisement (chars)
  "Return an eSMS advertisement string.

CHARS says the maximum size of the advertisement."

  (cond
   ((>= chars 22) "\n-- eSMS from XEmacs --")
   ((>= chars 21) "\n- eSMS from XEmacs - ")
   ((>= chars 20) "\n- eSMS from XEmacs -")
   ((>= chars 19) "\n- eSMS from XEmacs!")
   ((>= chars 18) "\n- eSMS from XEmacs")
   ((>= chars 17) "\n-eSMS from XEmacs")
   ((>= chars 16) "\neSMS from XEmacs")
   ((>= chars 15) "\n-- XEmacs --")
   ((>= chars 12) "\n- XEmacs -")
   ((>= chars 10) "\n- XEmacs!")
   ((>= chars  9) "\n-XEmacs-")
   ((>= chars  8) "\nXEmacs!")
   ((>= chars  7) "\nXEmacs")
   ))


;;;
;; User interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun esms--ssp-prioritise (ssp-symbol)
  "Make an SSP The highest priority.

SSP-SYMBOL the symbol of the SSP to set high priority, should be a key
from `esms--ssp-alist'

Assumes SSP-SYMBOL is a member of `esms-ssp-priority-list'"

  (setq esms-ssp-priority-list (cons ssp-symbol (delete ssp-symbol esms-ssp-priority-list)))
  )

(defun esms--ssp-menu-filter (menu)

  "Generate a \"menu description\" On basis of available SSPs.

MENU is not used.

The available SSPs are the ones found in `esms--ssp-alist', a menu is
generated with priority according to `esms-ssp-priority-list'."

  ;; menu is not used.
  (let* (
         (ssp-alist esms--ssp-alist)
         (menu-list '(
;;                      "----"
;;                      "--:singleLine"
;;                      "--:doubleLine"
;;                      "--:singleDashedLine"
;;                      "--:doubleDashedLine"
;;                      "--:noLine"
;;                      "--:shadowEtchedIn"
;;                      "--:shadowEtchedOut"
;;                      "--:shadowDoubleEtchedIn"
;;                      "--:shadowDoubleEtchedOut"
                      "--:shadowEtchedInDash";;Pretty good
;;                      "--:shadowEtchedOutDash"
;;                      "--:shadowDoubleEtchedInDash"
;;                      "--:shadowDoubleEtchedOutDash"
                      "SSP priority selection"))
         (ssp-priority-fun (lambda (ssp-symbol)
                             (let* ((priority-list esms-ssp-priority-list)
                                    (priority 1)
                                    )
                               (while (and priority-list (not (equal (car priority-list) ssp-symbol)))
                                 (setq priority-list (cdr priority-list)
                                       priority (1+ priority))
                                 )
                               (and priority-list priority) ;return the priority, or nil if end-of list
                               )
                             ))
         ssp-key
         ssp-priority
         )
    (while ssp-alist
      (setq ssp-key (car (car ssp-alist))
            ssp-priority (funcall ssp-priority-fun ssp-key)
            menu-list (cons
                       (vector
                        (format "%s %s"
                                (if ssp-priority
                                    (format "%s." ssp-priority)
                                  "   "
                                  )
                                (nth 1 (assoc ssp-key esms--ssp-alist))) ;;text-entry
                        `(esms--ssp-prioritise ',ssp-key)
                        ':active ssp-priority
                        )
                       menu-list)
            ssp-alist (cdr ssp-alist)
            )
      )
    (setq menu-list (cons
                     [ "Help on SSP selection" (popup-dialog-box (list
                                                 (format

"SMS Service Provider priority list:

When clicking on an SSP you set this SSP to have first priority, the
priority list is adjusted accordingly, the faded SSP are SSP that do
exist, but is currently not in priority list, so they will not be
used. You can see the priority to the left of the SSP name. The SSP
are attempted as SMS servers in increasing order starting with 1.

See description of variable esms-ssp-priority-list for how to change
the SSP priority list at startup.
Current value is %s.

Example:
Put
\(setq esms-ssp-priority-list '\(telebesked.dk/no\)\)
in your .emacs to change default SSP priority to only consider the
norweigean telebesked.dk SSP."

esms-ssp-priority-list)
                                                 [ "OK" 'nil t ] )) ]
                     (cons "--:singleDashedLine"
                           menu-list)))
    (reverse menu-list)
    )
  )

(when (string-match "XEmacs" emacs-version)
  (unless (memq 'esms menubar-configuration)
    (setq menubar-configuration (cons 'esms menubar-configuration))
    )
  )

(defvar esms--mainmenu '("eSMS" :config esms
                        [ "Send message" sms-send-message ]
                        (
                         "SMS Service Providers" :filter esms--ssp-menu-filter
                         "DUMMY";; will not show due to filter
                         )
                        [ "About eSMS" (popup-dialog-box 
                                        (list esms-about-string [ "OK" 'nil t ] )
                                        )
                          ]
                        )
  )

;; portable menu-code:
(easy-menu-define
 esms-main-easymenu nil "eSMS" esms--mainmenu)
;;seem not to be inserted in GNU Emacs
;;(easy-menu-add-item nil '("Tools") esms-main-easymenu "----")
(easy-menu-add-item nil nil esms-main-easymenu)


(provide 'esms)

;;; esms.el ends here

;Local Variables:
;time-stamp-start: "Last-Modified:[ 	]+\\\\?[\"<]+"
;time-stamp-end: "\\\\?[\">]"
;time-stamp-line-limit: 10
;time-stamp-format: "%4y-%02m-%02d %02H:%02M:%02S %:Z (%u)"
;End: 
