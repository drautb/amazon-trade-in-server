#lang racket

(require net/http-client
         xml
         xml/path
         "request-builder.rkt")

(provide get-trade-in-value)

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
    (hash-set! results 'Title (se-path* '(Title) response))
    (hash-set! results 'ISBN (se-path* '(EAN) response))
    (for ([item (se-path*/list '(Items) response)])
      (when (equal? (se-path* '(IsEligibleForTradeIn) item) "1")
          (hash-set! results
                     (string->symbol (se-path* '(Binding) item))
                     (se-path* '(TradeInValue FormattedPrice) item))))
    results))

(define (get-trade-in-value isbn)
  (get-value isbn))
