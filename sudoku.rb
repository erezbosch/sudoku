require 'colorize'

class Tile
  attr_reader :value, :given
  def initialize(value)
    @value = value
    @given = value != 0
  end

  def to_s
    return "-" if @value == 0
    @given ? @value.to_s.green : @value.to_s.blue
  end

  def value=(val)
    @value = val unless @given
  end
end

class Board
  def initialize(grid)
    @grid = grid
  end

  def [] pos
    row, col = pos
    @grid[row][col]
  end

  def []= pos, value
    row, col = pos
    @grid[row][col].value = value
  end

  def render
    @grid.each do |row|
      puts row.join(" ")
    end
  end

  def solved?
    rows_solved? && cols_solved? && squares_solved?
  end

  def rows_solved?
    @grid.all? { |row| nine_solved?(row) }
  end

  def cols_solved?
    @grid.transpose.all? { |col| nine_solved?(col) }
  end

  def squares_solved?
    squares.all? { |square| nine_solved?(square) }
  end

  def squares
    sqs = []

    (0..2).each do |row_counter|
      (0..2).each do |col_counter|
        square = @grid[3 * row_counter][(3 * col_counter)..(3 * col_counter + 2)]
        square += @grid[(3 * row_counter) + 1][(3 * col_counter)..(3 * col_counter + 2)]
        square += @grid[(3 * row_counter) + 2][(3 * col_counter)..(3 * col_counter + 2)]

        sqs << square
      end
    end
    sqs
  end

  def square_containing_pos(pos)
    row, col = pos
    start_row = (row / 3) * 3
    start_col = (col / 3)

    squares[start_row + start_col]
  end

  def nine_solved?(collection)
    values = collection.map { |element| element.value }
    values.sort == (1..9).to_a
  end

  def self.from_file(file)
    lines = File.readlines(file).map(&:chomp).map(&:chars)
    lines.map! { |line| line.map { |char| Tile.new(char.to_i) } }
    Board.new(lines)
  end

  def valid?(num, pos)
    row, col = @grid[pos[0]], @grid.transpose[pos[1]]
    sqr = square_containing_pos(pos)
    valid_for_tiles(num, row) && valid_for_tiles(num, col) && valid_for_tiles(num, sqr)
  end

  def valid_for_tiles(num, tiles)
    tiles.all? { |tile| tile.value != num }
  end
end

class Game
  def initialize board
    @board = board
  end

  def play
    until @board.solved?
      @board.render
      pos, value = take_guess
      @board[pos] = value
    end
    @board.render
    puts "glorious victory"
  end

  def take_guess
    puts "Please enter a position, followed by a value:"
    puts "(e.g. to put a '9' at top left, enter: 0 0 9)"
    input = nil
    input = gets.chomp.split(" ").map(&:to_i) until input_valid?(input)
    value = input.pop
    [input, value]
  end

  def pos_valid?(pos)
    pos.all? { |p| (0..8).include?(p) }
  end

  def value_valid?(val)
    (1..9).include?(val)
  end

  def input_valid?(input)
    return false if input.nil?
    pos_valid?(input[0..1]) && value_valid?(input[2])
  end
end

class Solver
  def initialize file
    @board = Board.from_file(file)
  end

  def solve(pos = first_empty_pos)
    @board.render
    puts ""

    if @board.solved?
      puts "solved"
      return true
    end

    (1..9).each do |num|
      if @board.valid?(num, pos)
        @board[pos] = num

        return true if solve(next_empty_pos(pos))

        @board[pos] = 0
      end
    end

    false
  end

  def next_empty_pos(pos)
    until @board[pos].value == 0
      return nil if pos == [8, 8]
      pos = next_pos(pos)
    end
    pos
  end

  def next_pos(pos)
    row, col = pos
    col == 8 ? (row,col = row+1, 0) : col += 1
    [row, col]
  end

  def first_empty_pos
    @board[[0,0]].value == 0 ? [0,0] : next_empty_pos([0,0])
  end
end

if __FILE__ == $PROGRAM_NAME
  s = Solver.new("puzzles/sudoku3.txt")
  s.solve
end
