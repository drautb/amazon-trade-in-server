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

### Local Testing

`.env` should contain the same values as the configuration environment. `foreman start` will start local server.

### Deployment

This app deploys to Heroku.

1. Create the app. From the root project directory:

```
heroku create --buildpack http://github.com/drautb/heroku-buildpack-racket.git amazon-trade-in-server
```

2. Make sure that a Procfile exists in the project root.

```
web: ./racketapp
```

3. Configure the environment.

```
heroku config:set PLTSTDERR=info ACCESS_KEY_ID=********* SECRET_KEY_ID=************ ASSOCIATE_TAG=***********
```

4. Ship it.

```
git push heroku master
```

Powered by [Racket][1].

[1]: http://racket-lang.org/