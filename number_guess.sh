#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

ASK_USERNAME(){
  echo -e "\nEnter your username:"
  read USERNAME

  USERNAME_CHARACTERS=${#USERNAME}
  if [[ $USERNAME_CHARACTERS -gt 22 ]]
  then
    echo "Username must be 22 characters or fewer. Please try again."
    ASK_USERNAME
  fi
}

ASK_USERNAME
RETURNING_USER=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")

if [[ -z $RETURNING_USER ]]
then
  INSERTED_USER=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  
  # Determine singular or plural for games and guesses
  GAMES_LABEL="games"
  if [[ $GAMES_PLAYED -eq 1 ]]
  then
    GAMES_LABEL="game"
  fi
  
  GUESSES_LABEL="guesses"
  if [[ $BEST_GAME -eq 1 ]]
  then
    GUESSES_LABEL="guess"
  fi

  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED $GAMES_LABEL, and your best game took $BEST_GAME $GUESSES_LABEL."
fi

# Get the user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

TRIES=1
GUESS=0

GUESSING_MACHINE(){
  while true
  do
    read GUESS
    if ! [[ $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not an integer, guess again:"
      continue
    fi

    if [[ $GUESS -eq $SECRET_NUMBER ]]
    then
      break
    fi

    TRIES=$((TRIES + 1))

    if [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo -e "\nIt's lower than that, guess again:"
    elif [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo -e "\nIt's higher than that, guess again:"
    fi
  done
}

echo -e "\nGuess the secret number between 1 and 1000:"
GUESSING_MACHINE

INSERTED_GAME=$($PSQL "INSERT INTO games (user_id, guesses) VALUES ($USER_ID, $TRIES)")
PLURAL_TRIES=$(if [[ $TRIES -eq 1 ]]; then echo "try"; else echo "tries"; fi)
echo -e "\nYou guessed it in $TRIES $PLURAL_TRIES. The secret number was $SECRET_NUMBER. Nice job!"