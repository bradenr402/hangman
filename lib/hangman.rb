require 'json'

class Game
  def initialize
    play_game
      File.delete("saved_games/#{@file_name}") if !Dir.empty?('saved_games/') && File.exist?("saved_games/#{@file_name}")
    play_again
  end

  def play_game
    unless Dir.empty?('saved_games/')
      puts ' Would you like to continue where you left off?'
      answer = ''
      until %w[y n].include?(answer)
        print " Enter 'y' to load saved game or 'n' to create new game:  "
        answer = gets.chomp.downcase
      end
      answer == 'y' ? load_game : new_game
    else
      print "\n  No saved games found. "
      new_game
    end

    until check_game_over || @word_guessed
      puts "\n        #{@revealed_word.join(' ')}"
      letter = guess_letter
      if letter == 'guess'
        guess_word
      elsif letter == 'save'
        save_game
      else
        update_progress(letter)
          File.open("saved_games/#{@file_name}", 'w') { |file| file.puts(to_json) } if !Dir.empty?('saved_games/') && File.exist?("saved_games/#{@file_name}")
      end
    end
  end

  def welcome_message
    puts '  Welcome to Hangman!'
    puts '  The computer has randomly selected a secret word.'
    puts '  Your goal is to guess the secret word the computer has chosen.'
    puts "\n  When prompted, type one letter and press 'ENTER' to guess a letter."
    puts '  If you guess a letter incorrectly 6 times, you lose!'
    puts "\n  You may enter 'guess' at any time to guess the entire word."
    puts '  But be warned: if you guess the word incorrectly, you lose!'
    puts "\n  At any time, type 'save' and press 'ENTER' to save your progress for later."
    puts "\n  Good luck!"
  end

  def update_progress(letter)
    unless @secret_word.any? { |character| character == letter }
      puts "\n  Sorry, that letter is not in the secret word."
      @guesses_remaining -= 1
    else
      @secret_word.each_with_index { |character, index| @revealed_word[index] = character if character == letter }
    end
    puts "\n        Guesses remaining:  #{@guesses_remaining}"
    puts "             Letters used:  #{@guessed_letters.sort.join(' ')}"
  end

  def guess_letter
    print "\n  Enter a letter to guess:  "
    letter = gets.chomp.downcase
    until letter.match(/[a-z]/) && letter.length == 1 || letter == 'guess' || letter == 'save'
      puts '  Invalid guess! Please enter only one letter.'
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
      puts '  Invalid guess! Please enter only letters without any spaces.'
      print '  Enter your guess:  '
      guess = gets.chomp.downcase
    end

    if guess.split('') == @secret_word
      puts "\n  You guessed the secret word! You win!"
    else
      puts "\n  Incorrect! You failed to guess the word! You lose!"
      puts "  The secret word was: \"#{@secret_word.join}\""
    end
    @word_guessed = true
  end

  def check_game_over
    if @revealed_word == @secret_word
      puts "\n  You guessed the secret word! You win!"
      true
    elsif @guesses_remaining <= 0
      puts "\n  All out of guesses! You lose!"
      puts "  The secret word was:  \"#{@secret_word.join}\""
      true
    else
      false
    end
  end

  def play_again
    puts '  Would you like to play again?'
    again = ''
    until %w[y n].include?(again)
      print "  Enter 'y' to play again or 'n' to quit:  "
      again = gets.chomp.downcase
    end
    again == 'y' ? Game.new : exit
  end

  def save_game
    Dir.mkdir('saved_games') unless Dir.exist?('saved_games')


    if !Dir.empty?('saved_games/') && File.exist?("saved_games/#{@file_name}")
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
    sleep(1)
    puts " Type in the name of the game you'd like to open, or type 'cancel' to start a new game."

    saved_files = Dir.entries('saved_games/')
    saved_files.each { |file| saved_files.delete(file) if file == '.' || file == '..' }

    print ' Saved games:   '
    puts saved_files.sort.join(' ')
    print ' Open file: '
    @file_name = gets.chomp

    @file_name == 'cancel' ? new_game : File.open("saved_games/#{@file_name}", 'r') { |file| data = from_json(file) }

  end

  def new_game
    puts "Starting new game...\n\n"
    sleep(1)
    welcome_message

    @dictionary = File.read('google-10000-english-no-swears.txt').split
    @secret_word = []
    @secret_word = @dictionary.sample.split('') until @secret_word.size.between?(5, 12)
    @revealed_word = Array.new(@secret_word.size, '_')
    @guessed_letters = []
    @word_guessed == false
    @guesses_remaining = 6

    # @file_name == "This file doesn't exist. I'm just doing this to enable autosave functionality"
  end

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

Game.new