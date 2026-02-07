# Code

## DRY code 

Be fanatical about writing DRY code. Any time there is repeated logic, separate it out to a separate function. Do this in test code as well as app code.

## Models

Models that are likely to have much complexity (i.e. more than 60 lines) should be split up into concerns. See identity.rb for an example

# Tests

## Arrange/Act/Assert

Strictly use the Arrange/Act/Assert pattern like this:

Organize tests into describe and context blocks. `describe` block names should indicate the thing being tested. `context` block names should indicate the intention of the arranging that is happening in that block.

### Arrange

Nest context blocks inside each other, being careful to but the arranging at the appropriate levels to make it clear which arranging is for which purpose and to avoid duplication. Put default arranging at the higher context block and overrides lower.

Prefer to use `let()` for arranging. Failing that, use `before` blocks.

A good example of this is in the `#active_for_authentication?` tests in spec/models/identity_concerns/can_be_disabled_spec.rb

### Act

Each test should take a small number of actions (ideally one). 

Withing each context block, each distinct set of actions should have one or more tests, ideally one. Create one or more tests for the same distinct set of actions in order to avoid having a test name that describes lots of different unrelated assertions (see next section about Assert for more info).

### Assert

Each test should have a small number of assertions. 

When there are more than one assertion to make given a single set of actions in a single context block, make those assertions in a single test and use :aggregate_failures. A good example of this is in the "creates a user and identity" in spec/models/identity_concerns/supports_magic_links_spec.rb.

## Fixtures, data, etc.

For performance, avoid actually creating and saving things to the database unless necessary. We don't want to trigger callbacks that take time when it's not necessary. Prefer using `build_stubbed`.