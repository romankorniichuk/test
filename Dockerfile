FROM golang:1.20-alpine AS build
WORKDIR /src/
COPY main.go go.* /src/
RUN go get -d -v
RUN CGO_ENABLED=0 go build -o /bin/test

FROM scratch
COPY --from=build /bin/test /bin/test
ENTRYPOINT ["/bin/test"]