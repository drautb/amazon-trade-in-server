#lang racket

(require (planet dmac/spin)
         web-server/servlet
         json
         "trade-in-value.rkt")

(define PORT
  (let ([port (environment-variables-ref (current-environment-variables) #"PORT")])
    (if port
        (string->number (bytes->string/utf-8 port))
        5000)))

(define (json-response-maker status headers body)
  (response (if (eq? body #f) 404 status)
            (status->message status)
            (current-seconds)
            #"application/json; charset=utf-8"
            headers
            (lambda (op)
              (when body
                (write-json (force body) op)))))

(define (json-get path handler)
  (define-handler "GET" path handler json-response-maker))

(define (status) (λ ()
                   (log-info "Status requested.")
                   (make-hash (list (cons 'status "healthy")))))

;; Healthcheck
(json-get "/" (status))
(json-get "/status" (status))

;; Primary endpoint. Given an ISBN, this will attempt to
;; locate the AWS trade-in value of the book.
(json-get "/rest/value/:isbn"
          (λ (req)
            (let ([isbn (params req 'isbn)])
              (log-info "action=/rest/value isbn=~a" isbn)
              (let ([value-data (get-trade-in-value isbn)])
                (log-info "action=/rest/value isbn=~a response=~a" isbn (jsexpr->string value-data))
                value-data))))

(log-info "Starting server on port ~a" PORT)
(run #:port PORT
     #:listen-ip #f)