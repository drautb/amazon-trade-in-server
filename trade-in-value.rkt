#lang racket

(require net/http-client
         xml
         xml/path
         "request-builder.rkt")

(provide get-trade-in-value)

(define (find-title response)
  (or (se-path* '(Items Item ItemAttributes Title) response)
      (se-path* '(Title) response)))

(define (find-isbn response)
  (or (se-path* '(Items Item ItemAttributes ISBN) response)
      (se-path* '(Items Item ItemAttributes EISBN) response)
      (se-path* '(Items Item ItemAttributes EAN) response)))

(define (get-value isbn)
  (define params (make-hash))
  (hash-set! params "Operation" "ItemLookup")
  (hash-set! params "ResponseGroup" "ItemAttributes")
  (hash-set! params "IdType" "ISBN")
  (hash-set! params "SearchIndex" "All")
  (hash-set! params "ItemId" isbn)

  (define results (make-hash))

  (define-values (host uri) (build-request params))
  (log-info "action=get-value isbn=~a request-host=~a request-uri=~a" isbn host uri)
  (let-values ([(status-code header in-port) (http-sendrecv host uri)])
    (define raw-response (read-xml in-port))
    (log-info "action=get-value isbn=~a status-code=~a" isbn status-code)
    (define response (xml->xexpr (document-element raw-response)))
    (when (se-path* '(Items Request Errors Error Code) response)
      (set! results #f))
    (when results
      (define title (find-title response))
      (define isbn (find-isbn response))
      (unless (and title isbn)
        (log-error "Title or ISBN was #f! title=~a isbn=~a raw-response=~a" title isbn raw-response))
      (hash-set! results 'Title title)
      (hash-set! results 'ISBN isbn)
      (define trade-in-options '())
      (for ([item (se-path*/list '(Items) response)])
        (let ([eligible (se-path* '(IsEligibleForTradeIn) item)]
              [value (se-path* '(TradeInValue FormattedPrice) item)])
          (when (and (equal? eligible "1") value)
            (set! trade-in-options
                  (cons (make-hash
                          (list (cons (string->symbol (se-path* '(Binding) item))
                                      value)))
                        trade-in-options)))))
      (hash-set! results 'TradeInOptions trade-in-options))
    results))

(define (get-trade-in-value isbn)
  (get-value isbn))
