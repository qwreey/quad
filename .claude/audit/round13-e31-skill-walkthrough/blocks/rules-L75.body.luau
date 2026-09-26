-- source: references/rules-and-invariants.md:75-81
-- correct
Activated = function(inputObject, clickCount) end

-- wrong: there is no leading self
-- Activated = function(self, inputObject) end
