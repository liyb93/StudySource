#!/bin/sh
sudo honkit build
sudo honkit epub ./ ./books/book.epub
sudo honkit pdf ./ ./books/book.pdf
sudo honkit mobi ./ ./books/book.mobi
