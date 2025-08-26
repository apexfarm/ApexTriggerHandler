trigger AccountTrigger on Account (before update, after update) {

    Triggers.prepare()
        .beforeUpdate()
            .bindState(state)
            .bind('MyAccountHandler')
            .bind('AnotherAccountHandler')
        .afterUpdate()
            .bind('MyAccountHandler')
            .bind('AnotherAccountHandler')
        .execute();
}

// 1. a global flag to turn handlers off
// 2. better state management
// 3. bind instances of handlers, or strings? (performance is better?)
// 4. enhance for domain logic, such as validation, calculation, transformation
// 5. should be simple to use, rare case should not be considered

AccountTriggerState state = (AccountTriggerState) context.state.get(AccountTriggerState.class);
state.counter++;