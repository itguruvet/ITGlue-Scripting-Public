# ITGlue-Scripting-Public
This is a public repository of scripts that were developed internally at IT Guru, which we felt may be useful to the wider community

Clear-ITGlueOrphanConfiguratins was written to help clean up orphan configuratinos across all customers, and can be ran in several different modes with parameters and examples for most use casees.  It was written with the intention of running it from the PowerShell ISE, and may not work as expected if ran from the cmdline of VS Code  

Also I just realized there is something wrong with the data handoff to the function - until I get a chance to review, I recommend setting the parameters as variables, then manually running the begin,process,end function by right clicking and running that section individually --- something is wrong with the initial IT Glue connection piece with the current function which is only running right when using that approach.

Sorry for the half buit script, but with a little massaging this will work!
