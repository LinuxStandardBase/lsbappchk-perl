select ILMname, ILMappearedin, ILMwithdrawnin from InterpretedLanguageModule 
where ILMlanguage in (select ILid from InterpretedLanguage 
where ILname = 'Perl')
and ILMappearedin <>'' and ILMappearedin <= '3.2'
and (ILMwithdrawnin is NULL or ILMwithdrawnin > '3.2')
