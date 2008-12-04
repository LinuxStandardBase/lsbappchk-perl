SELECT ILMname,ILMappearedin,ILMwithdrawnin FROM InterpretedLanguageModule 
WHERE ILMlanguage IN (SELECT ILid FROM InterpretedLanguage 
WHERE ILname = 'Perl')
AND ILMappearedin <>'' AND ILMappearedin <= '3.2'
AND (ILMwithdrawnin IS NULL OR ILMwithdrawnin > '3.2')
ORDER BY ILMname
