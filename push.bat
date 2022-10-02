@ECHO OFF
IF (%1)==() (
    echo "You must put a message to push changes";
    goto end
)
@ECHO ON
git add .
git commit -m %1
git push -u origin main
rem git push heroku
:end