FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY . .

RUN go build -o main .


FROM scratch

COPY --from=builder /app/main ./main

COPY --from=builder /app/static ./static

EXPOSE 8080

CMD ["./main"]
