# Apex Trigger Handler

![](https://img.shields.io/badge/version-1.1.2-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

There are already many trigger handler libraries out there, but this one has some different approaches or advantanges such as state sharing, built in helper methods etc.. Just one class `Triggers.cls` with its corresponding test class `TriggersTest.cls`, and its minimal and simple.

------

### Release 1.1.2

1. Eliminate any DML statements in test class, so the library can be installed in any org.
2. **[Unit Test How-To](#unit-test-how-to)**: Add a private but `@TestVisible` helper method to mock the handler tests, so we don't need to do any DMLs in order to trigger the handlers.

------

### Features

1. Share common query results via context.state with the following handlers in the current trigger execution context.
2. Built-in helpers to perform common operations on trigger properties, such as detect field changes.
3. Control flow of handler execution with context.next(), context.stop(), and context.skips.

## Usage

To create a trigger handler, you will need to create a class that implements the `Triggers.Handler` interface and its `criteria` method, and the corresponding trigger event method interfaces, such as the `Triggers.BeforeUpdate` interface and its `beforeUpdate` method.

```java
public class MyAccountHandler implements Triggers.Handler, Triggers.BeforeUpdate {
    public Boolean criteria(Triggers.Context context) {
        return true;
    }

    public void beforeUpdate(Triggers.Context context) {
        // do stuff
    }
}
```

### Trigger

As you have noticed, why we are creating same handlers for different trigger events? This is because handlers may need to execute in different orders for different trigger events, we need to provide developers great controls over the order of executions.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .beforeUpdate()
            .bind(new MyAccountHandler())
            .bind(new AnotherAccountHandler())
        .afterUpdate()
            .bind(new AnotherAccountHandler())
            .bind(new MyAccountHandler())
        .execute();
}
```

### Trigger Handler

Please check the comments below for detailed explanations and tricks to customize a trigger handler.

```java
// 1. Use interfaces instead of a base class to extend a custom handler. With interface
// approach we can declare only the needed interfaces explicitly, which is much cleaner
// and clearer.
public class MyAccountHandler implements Triggers.Handler,
                                         Triggers.BeforeUpdate,
                                         Triggers.AfterUpdate {

    // 2. There is a "criteria" stage before any handler execution. This gives
    // developers chances to turn on and off the handlers according to
    // configurations at run time.
    public Boolean criteria(Triggers.Context context) {
        return Triggers.WHEN_ALWAYS;

        // 3. There are also helper methods to check if certain fields have changes
        // return context.props.isChangedAny(Account.Name, Account.Description);
        // return context.props.isChangedAll(Account.Name, Account.Description);
    }

    public void beforeUpdate(Triggers.Context context) {
        then(context);
    }

    public void afterUpdate(Triggers.Context context) {
        then(context);
    }

    private void then(Triggers.Context context) {
        // 4. All properties on Trigger have been exposed to context.props.
      	// Direct reference of Trigger.old and Trigger.new can be avoided,
        // instead use context.props.oldList and context.props.newList.
        if (context.props.isUpdate) {

            // 5. Use context.state to pass query or computation results down to all
            // following handlers within the current trigger context, i.e. before update.
            Integer counter = (Integer)context.state.get('counter');
            if (counter == null) {
                context.state.put('counter', 0);
            } else {
                context.state.put('counter', counter + 1);
            }

            // 6. Use context.skips or Triggers.skips to prevent specific handlers from
            // execution. Please do remember restore the handler when appropriate.
            context.skips.add(ContactHandler.class);
            List<Contact> contacts = ...;
            Database.insert(contacts);
            context.skips.remove(ContactHandler.class);

            // 7-1. Call context.next() to execute the next handler. It is optional to use,
            // unless some following up logics need to be performed after all following
            // handlers finished.
            context.next();

            // 7-2. If context.stop() is called instead of context.next(), any following
            // handlers won't be executed, just like the STOP in process builder.
            context.stop();
        }
    }
}
```

### More on Skips

`context.skips` references the same global static variable `Triggers.skips`. If you want to skip handlers in contexts rather than a trigger handler. Please use `Triggers.skips` instead. For example, when you want to skip a trigger handler in a batch class:

```java
global class AccountUpdateBatch implements Database.Batchable<sObject> {
    ...
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Triggers.skips.add(MyAccountHandler.class);
        // Update accounts...
        Triggers.skips.remove(MyAccountHandler.class);
    }
    ...
}
```

Or you can skip the handler during batch execution in the criteria phase:

```java
public class MyAccountHandler implements Triggers.Handler, Triggers.BeforeUpdate {
    public Boolean criteria(Triggers.Context context) {
        return !System.isBatch();
    }
    ...
}
```

### Unit Test How-To

The following method is private but `@TestVisible`, it can be used in test methods to supply mock recoreds for old and new lists. So we don't need to perform DMLs to trigger the real triggers.

```java
List<SObject> oldList = new List<SObject> {
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'Old Name 1'),
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'Old Name 2'),
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'Old Name 3')}

List<SObject> newList = new List<SObject> {
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'New Name 1'),
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'New Name 2'),
    new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'New Name 3')}

Triggers.prepare(TriggerOperation.Before_Update, oldList, newList)
    .beforeUpdate()
        .bind(new MyAccountHandler())
    .execute();
```

## APIs

### Trigger Handler Interfaces

| Interface               | Method to Implement                             |
| ----------------------- | ----------------------------------------------- |
| Triggers.Handler        | `Boolean criteria(Triggers.Context context);`   |
| Triggers.BeforeInsert   | `void beforeInsert(Triggers.Context context);`  |
| Triggers.AfterInsert    | `void afterInsert(Triggers.Context context);`   |
| Triggers.BeforeUpdate   | `void beforeUpdate(Triggers.Context context);`  |
| Triggers.AfterUpdate    | `void afterUpdate(Triggers.Context context);`   |
| Triggers.BeforeDelete   | `void beforeDelete(Triggers.Context context);`  |
| Triggers.AfterDelete    | `void afterDelete(Triggers.Context context);`   |
| Triggers.BeforeUndelete | `void afterUndelete(Triggers.Context context);` |

### Triggers.Context

| Property/Method | Type                | Description                                                  |
| --------------- | ------------------- | ------------------------------------------------------------ |
| context.props   | Triggers.Props      | All properties on Trigger are exposed by this class. In addition there are frequently used helper methods and a convinient sObjectType property, in case reflection is needed . |
| context.state   | Map<Object, Object> | A map provided for developers to pass any value down to other handlers. |
| context.skips   | Triggers.Skips      | A set to store handlers to be skipped. Call the following methods to manage skips: `context.skips.add()`, `context.skips.remove()`, `context.skips.clear()` `context.skips.contains()` etc. |
| context.next()  | void                | Call the next handler.                                       |
| context.stop()  | void                | Stop execute any following handlers. A bit like the the stop in process builders. |

### Triggers.Props

#### Properties

| Property      | Type               | Description              |
| ------------- | ------------------ | ------------------------ |
| sObjectType   | SObjectType        | The current SObjectType. |
| isExecuting   | Boolean            | Trigger.isExecuting      |
| isBefore      | Boolean            | Trigger.isBefore         |
| isAfter       | Boolean            | Trigger.isAfter          |
| isInsert      | Boolean            | Trigger.isInsert         |
| isUpdate      | Boolean            | Trigger.isUpdate         |
| isDelete      | Boolean            | Trigger.isDelete         |
| isUndelete    | Boolean            | Trigger.isUndelete       |
| oldList       | List\<SObject\>    | Trigger.old              |
| oldMap        | Map\<Id, SObject\> | Trigger.oldMap           |
| newList       | List\<SObject\>    | Trigger.new              |
| newMap        | Map\<Id, SObject\> | Trigger.newMap           |
| operationType | TriggerOperation   | Trigger.operationType    |
| size          | Integer            | Trigger.size             |

#### Methods

**Note**: the following `isChanged` method has the same behavior has the `ISCHANGED` formula:

> - This function returns `false` when evaluating any field on a newly created record.
> - If a text field was previously blank, this function returns `true` when it contains any value.
> - For number, percent, or currency fields, this function returns `true` when:
>   - The field was blank and now contains any value
>   - The field was zero and now is blank
>   - The field was zero and now contains any other value
>

| Method                                                       | Type      | Description                                                  |
| ------------------------------------------------------------ | --------- | ------------------------------------------------------------ |
| - `isChanged(SObjectField field1)`                           | Boolean   | Check if any record has a field changed during an update.    |
| - `isChangedAny(SObjectField field1, SObjectField field2)`<br>- `isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3)`<br>- `isChangedAny(List<SObjectField> fields)` | Boolean   | Check if any record has multiple fields changed during an update. Return `true` if any specified field is changed. |
| - `isChangedAll(SObjectField field1, SObjectField field2)`<br>- `isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3)`<br>- `isChangedAll(List<SObjectField> fields)` | Boolean   | Check if any record has multiple fields changed during an update. Return `true` only if all specified fields are changed. |
| - `filterChanged(SObjectField field1)`                       | Set\<Id\> | Filter IDs of records have a field changed during an update. |
| - `filterChangedAny(SObjectField field1, SObjectField field2)`<br/>- `filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3)`<br/>- `filterChangedAny(List<SObjectField> fields)` | Set\<Id\> | Filter IDs of records have mulantiple fields changed during an update. Return IDs if any specified field is changed. |
| - `filterChangedAll(SObjectField field1, SObjectField field2)`<br/>- `filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3)`<br/>- `filterChangedAll(List<SObjectField> fields)` | Set\<Id\> | Filter IDs of records have mulantiple fields changed during an update. Return IDs only if all specified fields are changed. |

## License

BSD 3-Clause License
