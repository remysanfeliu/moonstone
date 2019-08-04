# MoonStone

MoonStone is a tiny update-manager for your Swift app. 

You can easily define multiple upgrade paths for each Bundle your app uses.
Simply add the repo to your Cocoapods dependency, instanciate a `Moonstone` object and start adding
updagre paths. Once all the paths have been define, run `evolve()` and watch your app get the next level !

The API is designed to be fluent and always returns the current MoonStone, and the versions are checked against SemVer 2.0.0 specification : 
```
MoonStone(for: Bundle.main)
    .evolution(to: "1.2.3") {
        // Apply necessary local changes for version 1.2.3
    }
    .evolution(to: "2") {
        // Apply necessary change to reach version 2 from version 1.2.3
    }
    .evolution(if: { /* This condition returns true */ }) {
        // Apply changes required if the predicate above is true
    }
    .evolve()
```

Your app must follow the SemVer 2.0 specification for MoonStone to work properly.