#!/bin/bash
cd $TRAVIS_BUILD_DIR
  # Run all tests except pending ones
  echo "- mix test --exclude pending --trace "
        mix test --exclude pending --trace   

      if [ "$?" -eq 0 ]; then
            echo "mix test successfully completed"
          else 
            echo "mix test Finished with errors ,exited with 1"
            mix_test=1 ;
      fi;


  # Submit code coverage report to Coveralls
  # Add --pro if you using private repo.
  echo "- mix coveralls.travis --exclude pending ;"  
        mix coveralls.travis --exclude pending 

      if [ "$?" -eq 0 ]; then
            echo "mix coveralls.travis successfully completed"
          else 
            echo "mix coveralls.travis finished with errors , exited with 1"
            mix_test=1;
      fi;


  # Run static code analysis 
  echo "- mix credo -a ; "
        mix credo -a

       if [ "$?" -eq 0 ]; then
            echo "mix credo successfully completed"
          else 
            echo "mix credo finished with errors, exited with 1"
            mix_test=1;
       fi;

  # Check code style
  echo "- mix dogma;"
        mix dogma
      if [ "$?" -eq 0 ]; then
     				echo "mix dogma successfully completed"
   				else 
   	 				echo "mix dogma finished with errors, exited with 1"
   	 				mix_test=1;
      fi;


if [ "${mix_test}" == "1" ]; then
  echo "finished with errors"
  exit 1;
fi;