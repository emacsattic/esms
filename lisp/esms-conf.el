;;; esms-conf.el --- Send SMS messages directly from XEmacs
;;
;; $Id: esms-conf.el,v 1.2 2002/01/15 08:28:03 jarl Exp $
;;
;; $Id: esms-conf.el,v 1.2 2002/01/15 08:28:03 jarl Exp $
;; OriginalAuthor: Jarl Friis <jarl@diku.dk>
;; Maintainer: Jarl Friis <jarl@diku.dk>
;; Created: 12-09 , 2001
;; Last-Modified: <2002-01-15 09:45:26 CET (jarl)>
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

;; Adding to available SSPs
(defun esms--default-configuration ()
  "Sets up the default configuration for eSMS, i.e. the SSP-priority list `esms--ssp-alist'."
  (setq esms--ssp-alist nil)
  ;;
  ;;
  (esms-add-ssp
   'opasia.dk ; the key
   "opasia.dk (DK)" ; text for menus
   "This SSP does not support multiple spaces, nor does it support newlines." ; description
   (esms--generic-message-length-func "smssender@mail.dk Fra: ..." "");;seem to need sender
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--opasia.dk-request)
      country area number message from))
   '((45 "")) ; area list, accept only empty area codes
   )
  
  (esms-add-ssp
   'tiscali.dk
   "tiscali.dk (DK)"
   "This SSP does not support multiple spaces, nor does it support newlines."   
   (esms--generic-message-length-func "smsgw@tiscali.dk (Fra) " " ")
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--tiscali.dk-request)
      country area number message from))
   '((45 "")) ; area list, accept only empty area codes
   )
  
  (esms-add-ssp
   'telebesked.dk
   "telebesked.dk (DK)"
   "This SSP supports multiple spaces."
   (esms--generic-message-length-func "sms@telebesked.dk (Telebesked) (Fra) " " ");;double checked, OK
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--telebesked.dk-request)
      country area number message from))
   '((45 "")) ; area list, accept only empty area codes
   )
  
  (esms-add-ssp
   'telebesked.dk/no
   "telebesked.dk/no (NO)"
   "The norweigian version of telebesked.dk, This SSP supports multiple spaces. SSP is untested"
   (esms--generic-message-length-func "sms@telebesked.dk (Telebesked) (Fra) " " ");;A qualified guess.
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--telebesked.dk/no-request)
      country area number message from))
   '((47 "")) ; area list, accept only empty area codes
   )
  
  (esms-add-ssp
   'myorange.dk/besked
   "myorange.dk/besked (DK)"
   "This SSP supports newlines. It pads spaces between the message and the ad"
   (esms--generic-message-length-func "** Gratis SMS sendt fra myorange.dk **" "Fra: \n")
;           ,(esms--generic-message-length-func "** Gratis  myorange.dk **" "Fra: \n");;double checked, OK
   'esms--myorange.dk-send-message
   '((45 "")) ; area list, accept only empty area codes
   )

  (esms-add-ssp
   'uk.gsmbox.com
   "uk.gsmbox.com (UK)"
   "Not much is known about this SSP"
   (esms--generic-message-length-func "" "");not much is known
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--uk.gsmbox.com-request
        esms--uk.gsmbox.com-request2)
      country area number message from))
   '((44 "370" "374" "378" "385" "401" "402" "403" "410" "411" "421" "441" "467" "468" "498" "585" "589" "772" "780" "798" "802" "831" "836" "850" "860" "966" "973" "976" "4481" "4624" "7000" "7002" "7074" "7624" "7730" "7765" "7771" "7781" "7787" "7866" "7939" "7941" "7956" "7957" "7958" "7961" "7967" "7970" "7977" "7979" "8700" "9797")) ; area list
   )

  (esms-add-ssp
   'es.gsmbox.com
   "es.gsmbox.com (ES)"
   "Not much is known about this SSP"
   (esms--generic-message-length-func "" "");not much is known
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--es.gsmbox.com-request
        esms--es.gsmbox.com-request2)
      country area number message from))
   '((34 "600" "605" "606" "607" "608" "609" "610" "615" "616" "617" "619" "620" "626" "627" "629" "630" "636" "637" "639" "646" "647" "649" "650" "651" "652" "653" "654" "655" "656" "657" "658" "659" "660" "661" "662" "666" "667" "669" "670" "676" "677" "678" "679" "680" "686" "687" "689" "690" "696" "697" "699")) ; area list
   )
  
  (esms-add-ssp
   'it.gsmbox.com
   "it.gsmbox.com (IT)"
   "Not much is known about this SSP"
   (esms--generic-message-length-func "" "");not much is known
   (lambda (country area number message from)
     (esms--generic-HTTP-chain-requester
      `(esms--it.gsmbox.com-request
        esms--it.gsmbox.com-request2)
      country area number message from))
   '((39 "333" "334" "335" "338" "339" "330" "336" "337" "360" "368" "340" "347" "348" "349" "320" "328" "329" "380" "388" "389")) ; area list
   )
  )


(provide 'esms-conf)

;;; esms-conf.el ends here

;Local Variables:
;time-stamp-start: "Last-Modified:[ 	]+\\\\?[\"<]+"
;time-stamp-end: "\\\\?[\">]"
;time-stamp-line-limit: 10
;time-stamp-format: "%4y-%02m-%02d %02H:%02M:%02S %:Z (%u)"
;End: 

