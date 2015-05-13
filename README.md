Amazon Trade-in Server
======================

Provides a simple endpoint where you request the trade-in value for a book on Amazon.com.

### Example

Request:

```
curl -X GET localhost:8080/rest/value/9780136042594
```

Where `9780136042594` is the ISBN of a book.

Response:

```json
{
  "Title": "Artificial Intelligence: A Modern Approach (3rd Edition)",
  "ISBN": "9780136042594",
  "TradeInOptions": [
    {
       "Hardcover": "$89.18"
    }
  ]
}
```

`TradeInOptions` will be an empty list if the book isn't currently eligible for trade-ins.

The status code will be `404` if no book with the given ISBN could be found.

### Deployment

Make sure AWS credentials are in your environment or in `.aws/config`.

```
aws cloudformation validate-template --template-body file:///Users/drautb/GitHub/amazon-trade-in-server/cloudformation.json
```

```
aws cloudformation create-stack --stack-name amazon-trade-in-server --template-body file:///Users/drautb/GitHub/amazon-trade-in-server/cloudformation.json --tags Key=project,Value=amazon-trade-in-server --parameters ParameterKey=AccessKeyId,ParameterValue=[ACCESS KEY ID] ParameterKey=SecretKeyId,ParameterValue=[SECRET KEY ID] ParameterKey=AssociateTag,ParameterValue=[ASSOCIATE TAG]
```

```
aws cloudformation describe-stacks --stack-name amazon-trade-in-server
```

Powered by [Racket][1].

[1]: http://racket-lang.org/