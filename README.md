haskell-kafka [![Build Status](https://travis-ci.org/yanatan16/haskell-kafka.svg)](https://travis-ci.org/yanatan16/haskell-kafka)
=============

### NOT MAINTAINED. SEE [cosbynator/haskakafka](https://github.com/cosbynator/haskakafka)

An Apache Kafka driver in Haskell using the C driver [librdkafka](https://github.com/edenhill/librdkafka).

## Installation

Install [librdkafka](https://github.com/edenhill/librdkafka)

```
git clone https://github.com/edenhill/librdkafka
cd librdkafka
./configure
make
sudo make install
```

Now build haskell-kafka

```
cabal-dev install-deps
cabal-dev configure --enable-tests
cabal-dev build
cabal-dev test
```
