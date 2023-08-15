require 'json'

module Serializable
  def to_json
    JSON.dump ({
      secret_word: @secret_word,
      guesses_remaining: @guesses_remaining,
      revealed_word: @revealed_word,
      guessed_letters: @guessed_letters,
    })
  end

  def from_json(save_game)
    data = JSON.parse(File.read(save_game))

    @secret_word = data["secret_word"]
    @guesses_remaining = data["guesses_remaining"]
    @revealed_word = data["revealed_word"]
    @guessed_letters = data["guessed_letters"]
  end
end

class Game
  include Serializable

  def initialize
    play_game
      File.delete("saved_games/#{@file_name}") if File.exist?("saved_games/#{@file_name}") && !File.directory?("saved_games/#{@file_name}")
    play_again
  end

  def play_game
    unless Dir.empty?('saved_games/')
      puts ' Would you like to continue where you left off?'
      answer = ''
      until %w[y n].include?(answer)
        print " Enter '#{'y'.green}' to load saved game or '#{'n'.blue}' to create new game:  "
        answer = gets.chomp.downcase
      end
      answer == 'y' ? load_game : new_game
    else
      print "\n  No saved games found."
      new_game
    end

    until check_game_over || @word_guessed
      puts "\n        #{@revealed_word.join(' ')}"
      letter = guess_letter
      if letter == 'guess'
        guess_word
      elsif letter == 'save'
        save_game
      elsif letter == 'quit'
        exit
      else
        update_progress(letter)
          File.open("saved_games/#{@file_name}", 'w') { |file| file.puts(to_json) } if File.exist?("saved_games/#{@file_name}") && !File.directory?("saved_games/#{@file_name}")
      end
    end
  end

  def welcome_message
    puts '  Welcome to Hangman!'
    puts '  The computer has randomly selected a secret word.'
    puts "  #{'To win the game'.underline}, you must guess the secret word the computer has chosen."
    puts "\n  To guess a letter, type the letter you'd like to guess and press '#{'ENTER'.blue}'."
    puts "  The computer will reveal any instance of that letter in the secret word."
    puts "  If you guess a letter incorrectly #{'6 times'.red}, #{'you lose'.underline}!"
    puts "\n  You may enter '#{'guess'.green}' at any time to guess the entire word."
    puts "  #{'But be warned!'.red.italic} If you #{'fail'.red} to guess the word correctly, #{'you lose'.underline}!"
    puts "\n  At any time, type '#{'save'.green}' and press '#{'ENTER'.blue}' to save your progress for later."
    puts "\n  You may also type '#{'quit'.red}' at any time to quit the game without saving."
    puts "\n  Good luck!"
  end

  def update_progress(letter)
    unless @secret_word.any? { |character| character == letter }
      puts "\n  Sorry, that letter is not in the secret word."
      @guesses_remaining -= 1
    else
      @secret_word.each_with_index { |character, index| @revealed_word[index] = character if character == letter }
    end
    puts "\n        Guesses remaining:  #{@guesses_remaining.to_s.red}"
    puts "             Letters used:  #{@guessed_letters.sort.join(' ').blue}"
  end

  def guess_letter
    print "\n  Enter a letter to guess:  "
    letter = gets.chomp.downcase
    until letter.match(/[a-z]/) && letter.length == 1 || letter == 'guess' || letter == 'save' || letter == 'quit'
      puts '  Invalid guess! Please enter exactly one letter.'.italic
      print "\n  Enter a letter to guess:  "
      letter = gets.chomp.downcase
    end

    if @guessed_letters.include?(letter)
      puts '  You have already guessed that letter! Try again.'
      guess_letter
    else
      @guessed_letters << letter if letter.length == 1
    end
    letter
  end

  def guess_word
    print '  Enter your guess:  '
    guess = gets.chomp.downcase
    until guess.match(/[a-z]/) && !guess.include?(' ')
      puts '  Invalid guess! Please enter only letters without any spaces.'.italic
      print '  Enter your guess:  '
      guess = gets.chomp.downcase
    end

    if guess.split('') == @secret_word
      puts "\n  You guessed the secret word! You win!"
    else
      puts "\n  Sorry, that is incorrect. You lose!"
      puts "  The secret word was: \"#{@secret_word.join.italic.blue}\""
    end
    @word_guessed = true
  end

  def check_game_over
    if @revealed_word == @secret_word
      puts "\n  You guessed the secret word! You win!"
      true
    elsif @guesses_remaining <= 0
      puts "\n  All out of guesses! You lose!"
      puts "  The secret word was:  \"#{@secret_word.join.italic.blue}\""
      true
    else
      false
    end
  end

  def play_again
    puts "\n  Would you like to play again?".italic
    again = ''
    until %w[y n].include?(again)
      print "  Enter '#{'y'.green}' to play again or '#{'n'.red}' to quit:  "
      again = gets.chomp.downcase
    end
    again == 'y' ? Game.new : exit
  end

  def save_game
    Dir.mkdir('saved_games') unless Dir.exist?('saved_games')

    if File.exist?("saved_games/#{@file_name}") && !File.directory?("saved_games/#{@file_name}")
      File.open("saved_games/#{@file_name}", 'w') { |file| file.puts(to_json) }
      puts "File saved to:  #{@file_name}"
    else
      id = 1
      saved_successfully = false
      until saved_successfully
        if File.exist?("saved_games/save_game#{id}.json")
          id += 1
        else
          File.open("saved_games/save_game#{id}.json", 'w') { |file| file.puts(to_json) }
          saved_successfully = true
        end
      end
    puts "File saved to: save_game#{id}.json"
    end
    exit
  end

  def load_game
    puts " Type in the number of the saved game you'd like to open, or type 'cancel' to start a new game."
    saved_files = Dir.entries('saved_games/')
    saved_files.sort!.shift(2) # removes '.' and '..' directories

    files_hash = {}
    saved_files.each do |file|
      files_hash["#{file.split('')[9]}"] = file
    end

    puts ' Saved games:   '
    files_hash.each { |key, value| puts "   #{key.red}: #{value.blue}"}
    print '\n Open file: '
    @file_name = "save_game#{gets.chomp}.json"
    puts "Opening #{@file_name}..."
    sleep(1)
    @file_name == 'save_gamecancel.json' ? new_game : File.open("saved_games/#{@file_name}", 'r') { |file| data = from_json(file) }
  end

  def new_game
    puts " Starting new game...\n\n"
    sleep(1)
    welcome_message

    @dictionary = File.read('google-10000-english-no-swears.txt').split
    @secret_word = []
    @secret_word = @dictionary.sample.split('') until @secret_word.size.between?(5, 12)
    @revealed_word = Array.new(@secret_word.size, '_')
    @guessed_letters = []
    @word_guessed == false
    @guesses_remaining = 6
  end
end

# class defining methods for colorizing output in terminal
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red; colorize(31) end
  def green; colorize(32) end
  def yellow; colorize(33) end
  def blue; colorize(34) end
  def pink; colorize(35) end
  def light_blue; colorize(36) end

  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
end

Game.new
