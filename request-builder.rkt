#lang racket

(require json
         net/base64
         net/sendurl
         net/uri-codec
         racket/date
         sha)

(provide build-request)

;; This is a script to properly build a API request for Amazon's product
;; advertising API.
;;
;; Sauce: http://docs.aws.amazon.com/AWSECommerceService/latest/DG/rest-signature.html

(define SCHEME "http://")
(define HOST "webservices.amazon.com")
(define METHOD "GET")
(define PATH "/onca/xml")

(define (get-env-value name)
  (bytes->string/utf-8 (environment-variables-ref (current-environment-variables) (string->bytes/utf-8 name))))

(define ASSOCIATE-TAG (get-env-value "ASSOCIATE_TAG"))
(define ACCESS-KEY-ID (get-env-value "ACCESS_KEY_ID"))
(define SECRET-KEY-ID (get-env-value "SECRET_KEY_ID"))

(define (current-timestamp)
  (parameterize ([date-display-format 'iso-8601])
    (string-append (date->string
                     (seconds->date (current-seconds) #f)
                     #t)
                   "Z")))

(define default-params
  (list "Service=AWSECommerceService"
        (string-append "AWSAccessKeyId=" (uri-encode ACCESS-KEY-ID))
        (string-append "AssociateTag=" (uri-encode ASSOCIATE-TAG))
        (string-append "Timestamp=" (uri-encode (current-timestamp)))
        "Version=2013-08-01"))

(define (build-request-to-sign params)
  (string-join
    (list METHOD
          HOST
          PATH
          (string-join (sort params string<?) "&"))
    "\n"))

(define (sign-request request)
  (define (generate-signature)
    (uri-encode
      (string-trim
        (bytes->string/utf-8
          (base64-encode
            (hmac-sha256
              (string->bytes/locale SECRET-KEY-ID)
              (string->bytes/locale request)))))))
  (string-append request
                 "&Signature="
                 (generate-signature)))

(define (build-request-uri request)
  (let ([pieces (string-split request "\n")])
    (string-append PATH "?" (fourth pieces))))

(define (build-request-url request)
  (string-append SCHEME HOST (build-request-uri request)))

(define (condense-params params)
  (for/list ([k (hash-keys params)])
    (string-append k "=" (uri-encode (hash-ref params k)))))

(define (build-request params)
  (define all-params (append default-params (condense-params params)))
  (define request-to-sign (build-request-to-sign all-params))
  (define final-request (sign-request request-to-sign))
  (values HOST (build-request-uri final-request)))
