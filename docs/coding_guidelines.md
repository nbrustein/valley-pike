# Code

## DRY code 

Be fanatical about writing DRY code. Any time there is repeated logic, separate it out to a separate function. Do this in test code as well as app code.

For example, in a test, replace repeated calls to the following with a helper `post_to_password_session_path`

```
post password_session_path,
        params:,
        headers:
```

## Models

Models that are likely to have much complexity (i.e. more than 60 lines) should be split up into concerns. See identity.rb for an example

## Migrations

You should never need `if exists` in a migration. You always know the state of the schema at each migratino.

# Tests

## Arrange/Act/Assert

Strictly use the Arrange/Act/Assert pattern like this:

Organize tests into describe and context blocks. `describe` block names should indicate the thing being tested. `context` block names should indicate the intention of the arranging that is happening in that block.

Since we're using rspec, sometimes the organization of expectations means that the Assert actually ends up happening before the Act.

### Arrange

Nest context blocks inside each other, being careful to but the arranging at the appropriate levels to make it clear which arranging is for which purpose and to avoid duplication. Put default arranging at the higher context block and overrides lower.

Prefer to use `let()` for arranging. Failing that, use `before` blocks.

A good example of this is in the `#active_for_authentication?` tests in spec/models/identity_concerns/can_be_disabled_spec.rb

### Act

Each example should take a small number of actions (ideally one). Taken together, the actions being tested is called a "target operation".

If it takes more than one line to define a target operation, then it should be defined in a helper method. If it is unambiguous within the context block, then name this method `act`.

It is a good pattern to define multiple target operations as a parameterized helper method, like `def act(prop_1:, prop_2)`

There are 3 possible structures for organizing examples in a context block:

 * One context block has a single example
   * The target operation is the first call in the example unless rspec expectations need to be set up before the act call
 * One context block has multiple examples with different target operations
   * Same as in the previous case, the target operation is the first call in each example
 * One context block has multiple examples, all with the same target operation
   * If rspec expectations mean that the "assert" needs to come before the "act", then each example sets up its expectations and then calls act
   * Otheriwse, the target operation is in a `before` block, like `before { act }`

### Assert

Each example should have a small number of assertions. 

When there are more than one assertion to make given a single set of actions in a single context block, make those assertions in a single example and use :aggregate_failures. A good example of this is in the "creates a user and identity" in spec/models/identity_concerns/supports_magic_links_spec.rb.

## Fixtures, data, etc.

For performance, avoid actually creating and saving things to the database unless necessary. We don't want to trigger callbacks that take time when it's not necessary. Prefer using `build_stubbed`.

Use FactoryBot to initialize/create objects.