require_relative 'Models/Author'
require_relative 'Models/Book'
require_relative 'Models/Reader'
require_relative 'Models/Order'
require 'faker'

class Library
  attr_accessor :authors, :books, :orders, :readers

  def initialize(authors = [], books = [], orders = [], readers = [])
    @authors = authors
    @books = books
    @orders = orders
    @readers = readers
  end

  def seed
    40.times do
      author_name = Faker::Book.author
      author_biography = Faker::Lorem.paragraph(4)
      book_title = Faker::Book.unique.title
      @authors << Author.new(author_name, author_biography)
      @books << Book.new(book_title, author_name)
    end

    100.times do
      name = Faker::Name.unique.name
      email = Faker::Internet.email(name)
      city = Faker::Address.city
      street = Faker::Address.street_name
      house = Faker::Address.building_number
      @readers << Reader.new(name, email, city, street, house)
    end

    100.times do
      book_id = rand(@books.length)
      reader_id = rand(@readers.length)
      @orders << Order.new(@books[book_id], @readers[reader_id])
    end
  end

  def save_to_file
    data = {}
    data[:authors] = @authors.map { |a| { name: a.name, biography: a.biography } }
    data[:books] = @books.map { |b| { title: b.title, author: b.author } }
    data[:readers] = @readers.map do |r|
      { name: r.name, email: r.email, city: r.city, street: r.street, house: r.house }
    end
    data[:orders] = @orders.map do |order|
      {
        book: data[:books].detect { |b| b[:title] == order.book.title },
        reader: data[:readers].detect { |r| r[:email] == order.reader.email },
        date: order.date.to_s
      }
    end
    File.open('src/Data.txt', 'w') { |file| file.write(data) }
  end

  def read_from_file
    got_data = eval(File.read('src/Data.txt'))
    got_data.each do |key, value|
      case key
      when :authors
        value.each { |a| @authors << Author.new(a[:name], a[:biography]) }
      when :books
        value.each { |b| @books << Book.new(b[:title], b[:author]) }
      when :readers
        value.each { |r| @readers << Reader.new(r[:name], r[:email], r[:city], r[:street], r[:house]) }
      when :orders
        value.each do |order|
          book = @books.detect { |b| b.title == order.dig(:book, :title) }
          reader = @readers.detect { |r| r.email == order.dig(:reader, :email) }
          date = Time.new(order[:date])
          @orders << Order.new(book, reader, date)
        end
      end
    end
  end

  def top_reader
    count = @orders.each_with_object({}) do |order, h|
      h[order.reader.name] = 0 unless h.key? order.reader.name
      h[order.reader.name] += 1
    end
    count.max_by { |_k, v| v }.first
  end

  def top_book
    count = @orders.each_with_object({}) do |order, h|
      h[order.book.title] = 0 unless h.key? order.book.title
      h[order.book.title] += 1
    end
    count.max_by { |_k, v| v }.first
  end

  def count_of_orders_book(position)
    count = @orders.each_with_object({}) do |order, h|
      h[order.book.title] = 0 unless h.key? order.book.title
      h[order.book.title] += 1
    end
    top = count.max_by(position) { |_k, v| v }
    top.dig(position - 1, 1)
  end
end
