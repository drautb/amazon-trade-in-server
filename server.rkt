#lang racket

(require (planet dmac/spin)
         web-server/servlet
         json
         "trade-in-value.rkt")

(define PORT
  (let ([port (environment-variables-ref (current-environment-variables) #"PORT")])
    (if port port "8080")))

(define (json-response-maker status headers body)
  (response status
            (status->message status)
            (current-seconds)
            #"application/json; charset=utf-8"
            headers
            (lambda (op) (write-json (force body) op))))

(define (json-get path handler)
  (define-handler "GET" path handler json-response-maker))

(define (status) (λ () (make-hash (list (cons 'status "healthy")))))

;; Healthcheck
(json-get "/" (status))
(json-get "/status" (status))

;; Primary endpoint. Given an ISBN, this will attempt to
;; locate the AWS trade-in value of the book.
(json-get "/rest/value/:isbn"
          (λ (req)
            (let ([isbn (params req 'isbn)])
              (get-trade-in-value isbn))))

(run #:port PORT)
