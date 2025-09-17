trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare().execute();

    Triggers.prepare()
        .bind('MyAccountHandler')
        .bind('AnotherAccountHandler')
        .bind('MyAccountHandler')
        .bind('AnotherAccountHandler')
        .execute();

    Triggers.prepare()
        .bind('MyAccountHandler')
        .bind('AnotherAccountHandler')
        .bind('MyAccountHandler')
        .bind('AnotherAccountHandler')
        .beforeUpdate()
            .bind('MyAccountHandler')
            .bind('AnotherAccountHandler')
        .afterUpdate()
            .bind('MyAccountHandler')
            .bind('AnotherAccountHandler')
        .execute();
}

// 1. (DONE) a global flag to turn handlers off
// 2. (DONE) better state management: strong typed, global control
// 3. (DONE) bind types of handlers, or strings? (performance is better?)
// 4. enhance for domain logic, such as validation, calculation, transformation (Performance cost significantly)
// 5. (DONE) should be simple to use, rare case should not be considered

AccountTriggerState state = (AccountTriggerState) context.state.get(AccountTriggerState.class);
state.counter++;
