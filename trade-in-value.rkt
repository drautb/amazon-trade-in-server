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
  (let-values ([(status-code header in-port) (http-sendrecv host uri)])
    (define response (xml->xexpr (document-element (read-xml in-port))))
    (when (se-path* '(Items Request Errors Error Code) response)
      (set! results #f))
    (when results
      (hash-set! results 'Title (find-title response))
      (hash-set! results 'ISBN (find-isbn response))
      (define trade-in-options '())
      (for ([item (se-path*/list '(Items) response)])
        (when (equal? (se-path* '(IsEligibleForTradeIn) item) "1")
          (set! trade-in-options
                (cons (make-hash
                        (list (cons (string->symbol (se-path* '(Binding) item))
                                    (se-path* '(TradeInValue FormattedPrice) item))))
                      trade-in-options))))
      (hash-set! results 'TradeInOptions trade-in-options))
    results))

(define (get-trade-in-value isbn)
  (printf "get-trade-in-value for ibsn: ~a" isbn)
  (get-value isbn))
