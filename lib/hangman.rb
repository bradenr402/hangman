class Game
  def initialize
    @dictionary = File.read('google-10000-english-no-swears.txt').split

    @secret_word = []
    until @secret_word.size <= 12 && @secret_word.size >= 5
      @secret_word = @dictionary.sample.split('')
    end

    @revealed = Array.new(@secret_word.size, '_')
    @guesses_remaining = 6
    @word_guessed == false
    @guessed_letters = []

    puts "Secret word: #{@secret_word.join}"

    welcome_message
    play
  end

  def play
    until check_game_over || @word_guessed
      puts "\n        #{@revealed.join(' ')}"
      letter = guess_letter

      if letter == 'guess'
        guess_word
      else
        update_progress(letter)
      end
    end
  end

  def welcome_message
    puts '  Welcome to Hangman!'
    puts '  The computer has selected a random word.'
    puts '  Your goal is to guess the secret word the computer has chosen.'
    puts "\n  When prompted, type one letter and press 'ENTER' to make your guess."
    puts '  If you guess a letter incorrectly 6 times, you lose!'
    puts "\n  You may also type 'guess' and press 'ENTER' at any time to guess the entire word."
    puts '  But be warned: if you guess the word incorrectly, you lose immediately!'
    puts "\n  Good luck!"
  end

  def update_progress(letter)
    unless @secret_word.any? { |character| character == letter }
      puts "\n  Sorry, that letter is not in the secret word."
      @guesses_remaining -= 1
    else
      @secret_word.each_with_index do |character, index|
        if character == letter
          @revealed[index] = character

        end
      end
    end

    puts "\n        Guesses remaining: #{@guesses_remaining}"
    puts "             Letters used: #{@guessed_letters.sort.join(' ')}"
  end

  def guess_letter
    print "\n  Enter a letter to guess: "
    letter = gets.chomp.downcase
    until letter.match(/[a-z]/) && letter.length == 1 || letter == 'guess'
      puts '  Invalid guess! Please enter only one letter.'
      print "\n  Enter a letter to guess: "
      letter = gets.chomp.downcase
    end

    if @guessed_letters.include?(letter)
      puts '  You have already guessed that letter! Try again.'
      guess_letter
    else
      @guessed_letters << letter
    end
    letter
  end

  def guess_word
    print '  Enter your guess: '
    guess = gets.chomp.downcase
    until guess.match(/[a-z]/) && !guess.include?(' ')
      puts '  Invalid guess! Please enter only letters without any spaces.'
      print '  Enter your guess: '
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
    if @revealed == @secret_word
      puts "\n  You guessed the secret word! You win!"
      true
    elsif @guesses_remaining <= 0
      puts "\n  Out of guesses! You lose!"
      puts "  The secret word was: \"#{@secret_word.join}\""
      true
    else
      false
    end
  end
end

Game.new