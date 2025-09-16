# Apex Trigger Handler

![](https://img.shields.io/badge/version-2.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E95%25-brightgreen.svg)

The Salesforce Apex trigger framework for clean, scalable, and maintainable automation.

### Features

1. Custom settings to turn triggers on and off either globally or by specific sObjects.
2. Custom registry to register handlers via settings instead of code.
3. Control flow of handler execution with `context.next()`, `context.stop()`, and `context.skips`.

| Environment           | Installation Link                                                                                                                                         | Version |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgQAAS"><img src="docs/images/deploy-button.png"></a> | ver 2.0 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgQAAS"><img src="docs/images/deploy-button.png"></a>  | ver 2.0 |

### v2.0 Release Notes

- Support custom metadata type settings to register trigger handlers. ([jump to section](#12-bind-with-handler-settings))
- **Improve Consistency** (v1.2.1): Ids returned by `props.filterChangedAny` and `props.filterChangedAll` are now in the same Id orders of `props.newList`.

---

## Table of Contents

- [1. Setting](#1-setting)
  - [1.1 Custom Setting](#11-custom-setting)
  - [1.2 Custom Metadata](#12-custom-metadata)
- [2. Trigger](#2-trigger)
  - [2.1 Bind with Registry](#21-bind-with-registry)
  - [2.2 Bind with Apex](#22-bind-with-apex)
  - [2.3 Bind with Both](#23-bind-with-both)
- [3. Handler](#3-handler)
  - [3.1 Implementation](#31-implementation)
  - [3.2 Error Handling](#32-error-handling)
- [4. Props](#4-props)
- [5. States](#5-states)
  - [5.1 Implicit State](#51-implicit-state)
  - [5.2 Explicit State](#52-explicit-state)
- [6. Skipping Handlers](#6-skipping-handlers)
  - [6.1 Skipping Within a Handler](#61-skipping-within-a-handler)
  - [6.2 Skipping Outside a Handler](#62-skipping-outside-a-handler)
- [7. Tests](#7-tests)
  - [7.1 Test with Mockup Data](#71-test-with-mockup-data)
  - [7.2 Test with Mockup Library](#72-test-with-mockup-library)
- [8. APIs](#8-apis)
  - [8.1 Trigger Handler Interfaces](#81-trigger-handler-interfaces)
  - [8.2 Triggers.Context](#82-triggerscontext)
  - [8.3 Triggers.Props](#83-triggersprops)
- [9. License](#9-license)

## 1. Setting

### 1.1 Custom Setting

<img src="docs/images/custom-settings.png" width=600>

The `Registry Has Priority` setting determines whether handlers registered via custom metadata types take precedence over those registered directly in Apex code. For more information about bypass flags, refer to the table below:

| Bypass Triggers | Bypass SObjects                       | Description                                                          |
| --------------- | ------------------------------------- | -------------------------------------------------------------------- |
| false           | Empty                                 | By default, no trigger handlers are bypassed.                        |
| true            | Empty                                 | All trigger handlers registered through this framework are bypassed. |
| true            | Account<br />Contact<br />Opportunity | Only trigger handlers for the specified SObjects are bypassed.       |
| false           | Account<br />Contact<br />Opportunity | No trigger handlers are bypassed, even for the specified SObjects.   |

### 1.2 Custom Metadata

<img src="docs/images/custom-metadata.png" width=770>

| Field Name      | Data Type | Description                                                                                                       |
| --------------- | --------- | ----------------------------------------------------------------------------------------------------------------- |
| SObject         | Text      | **Required.** The API name of the SObject to which the handler applies.                                           |
| Trigger Event   | Picklist  | **Required.** Defaults to `Any Event`. When set to `Any Event`, the handler is applied to all implemented events. |
| Handler Class   | Text      | **Required.** The name of the Apex class that implements the handler logic.                                       |
| Execution Order | Number    | **Required.** Determines the sequence in which handlers are executed.                                             |
| Is Active       | Checkbox  | Indicates whether the handler is enabled or disabled.                                                             |

## 2. Trigger

### 2.1 Bind with Registry

Load trigger handlers from the registry. Each handler is automatically bound to the appropriate SObject trigger event.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare().execute();
}
```

### 2.2 Bind with Apex

Handlers can be bound using either class types or class names. Using class names is often preferred for flexibility. You can bind handlers to all events for simpler control, or to specific events for more granular management.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .bind(AccountHandler01.class) // handlers bound to any event
        .bind('AccountHandler02')
        .beforeUpdate()               // handlers bound to a specific event
            .bind(AccountHandler03.class)
            .bind('AccountHandler04')
        .execute();
}
```

### 2.3 Bind with Both

You can register trigger handlers using both metadata and Apex code simultaneously. By default, handlers registered via metadata are loaded automatically and take precedence. If you want handlers registered in Apex code to have priority, adjust the `Registry Has Priority` setting as described above.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .bind(AccountHandler01.class)
        .execute();
}
```

## 3. Handler

### 3.1 Implementation

To create a trigger handler, define a class that implements the appropriate handler interfaces. See the example below for detailed comments and tips on how to customize your trigger handler.

```java
// 1. Explicitly declare the required interfaces for clarity and maintainability.
public class AccountTriggerHandler implements Triggers.BeforeInsert, Triggers.BeforeUpdate {

    // 2. This method runs before any handler logic, allowing you to determine if
    //    the handler should execute for the current context.
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        handleExecute(context);
    }

    public void beforeUpdate(Triggers.Context context) {
        handleExecute(context);
    }

    private void handleExecute(Triggers.Context context) {
        // 3-1. Optionally call context.next() to execute the next handler.
        //      This is useful if you need to perform logic after all subsequent handlers run.
        context.next();

        // 3-2. Optionally call context.stop() to prevent any further
        //      handlers from executing, similar to the STOP action in Process Builder.
        context.stop();
    }
}
```

### 3.2 Error Handling

You can centralize exception handling for all subsequent handlers by implementing a dedicated error handler. This ensures that any exceptions thrown by handlers executed after `context.next()` are caught and managed in a single location. For example:

```java
public class ErrorTriggerHandler implements Triggers.BeforeInsert {
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        try {
            context.next();
        } catch (Exception ex) {
            // Handle exceptions from subsequent handlers here
        }
    }
}
```

## 4. Props

Avoid directly referencing static variables on the `Trigger` class. Instead, always access trigger properties through `context.props`, such as `context.props.oldList` and `context.props.newList`.

```java
public class AccountTriggerHandler implements Triggers.BeforeInsert {
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        if (context.props.isInsert) {
            for (Account account : (List<Account>) context.props.newList) {
                // do business logic
            }
        }
    }
}
```

## 5. States

### 5.1 Implicit State

State objects are automatically initialized the first time they are accessed.

```java
public class AccountTriggerHandler implements Triggers.BeforeInsert {
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        // Retrieve and update a state instance as needed.
        CounterState state = (CounterState) context.states.get(CounterState.class);
        ++state.counter;

        // Remove unused state instances to free resources.
        context.states.remove(CounterState.class);
    }
}
```

```java
public class CounterState implements Triggers.State {
    public Integer counter { get; set; }
}
```

### 5.2 Explicit State

State objects can also be set in advance and accessed later. Because both `Triggers.states` and `context.states` refer to the same singleton instance.

```java
Triggers.states.put(AccountState.class, new AccountState(contactList, orderList));
insert accounts; // Handlers can consume the pre-set AccountState.
Triggers.states.remove(AccountState.class);
```

## 6. Skipping Handlers

The global static variable `Triggers.skips` and `context.skips` reference the same singleton instance. This allows you to skip specific handlers both inside and outside handler contexts.

### 6.1 Skipping Within a Handler

You can temporarily skip other handlers from within a handler using `context.skips`:

```java
public class AccountTriggerHandler implements Triggers.BeforeInsert {
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        // Temporarily skip ContactHandler.
        context.skips.add(ContactHandler.class);
        insert contacts;
        // Restore the handler when done.
        context.skips.remove(ContactHandler.class);
    }
}
```

### 6.2 Skipping Outside a Handler

You can also skip handlers outside of trigger handler contexts, such as in a batch class:

```java
global class AccountUpdateBatch implements Database.Batchable<SObject> {
    global void execute(Database.BatchableContext context, List<SObject> scope) {
        Triggers.skips.add(MyAccountHandler.class);
        insert accounts;
        Triggers.skips.remove(MyAccountHandler.class);
    }
}
```

## 7. Tests

### 7.1 Test with Mockup Data

The following method is private but `@TestVisible`, it can be used in test methods to supply mockup records for old and new lists. So we don't need to perform DMLs to trigger the handlers.

```java
@isTest
static void test_AccountTriggerHandler_BeforeUpdate {
    List<SObject> oldList = new List<Account> {
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'Old Name 1'),
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'Old Name 2'),
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'Old Name 3')}

    List<SObject> newList = new List<Account> {
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'New Name 1'),
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'New Name 2'),
        new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'New Name 3')}

    Triggers.prepare(TriggerOperation.Before_Update, oldList, newList)
        .beforeUpdate().bind(new MyAccountHandler()).execute();
}
```

### 7.2 Test with Mockup Library

The following demo is using [Apex Test Kit](https://github.com/apexfarm/ApexTestKit) as a mockup data library. The behavior will be the same as the above example, but a sophisticated mock data library can also generate mockup data with read-only fields, such as formula fields, roll-up summary fields and system fields.

```java
@isTest
static void test_AccountTriggerHandler_BeforeUpdate {
    // automatically generate fake IDs for oldList
    List<SObject> oldList = ATK.prepare(Account.SObjectType, 3)
        .field(Account.Name).index('Old Name {0}')
        .mock().get(Account.SObjectType);

    // IDs in oldList will be preserved in the newList
    List<SObject> newList = ATK.prepare(Account.SObjectType, oldList)
        .field(Account.Name).index('New Name {0}')
        .mock().get(Account.SObjectType);

    Triggers.prepare(TriggerOperation.Before_Update, oldList, newList)
        .beforeUpdate().bind(new MyAccountHandler()).execute();
}
```

## 8. APIs

### 8.1 Trigger Handler Interfaces

| Interface               | Method to Implement                                |
| ----------------------- | -------------------------------------------------- |
| Triggers.Handler        | `Boolean shouldExecute(Triggers.Context context);` |
| Triggers.BeforeInsert   | `void beforeInsert(Triggers.Context context);`     |
| Triggers.AfterInsert    | `void afterInsert(Triggers.Context context);`      |
| Triggers.BeforeUpdate   | `void beforeUpdate(Triggers.Context context);`     |
| Triggers.AfterUpdate    | `void afterUpdate(Triggers.Context context);`      |
| Triggers.BeforeDelete   | `void beforeDelete(Triggers.Context context);`     |
| Triggers.AfterDelete    | `void afterDelete(Triggers.Context context);`      |
| Triggers.BeforeUndelete | `void afterUndelete(Triggers.Context context);`    |

### 8.2 Triggers.Context

| Property/Method | Type                | Description                                                                                                                                                                                 |
| --------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| context.props   | Triggers.Props      | All properties on Trigger are exposed by this class. In addition there are frequently used helper methods and a convinient sObjectType property, in case reflection is needed .             |
| context.state   | Map<Object, Object> | A map provided for developers to pass any value down to other handlers.                                                                                                                     |
| context.skips   | Triggers.Skips      | A set to store handlers to be skipped. Call the following methods to manage skips: `context.skips.add()`, `context.skips.remove()`, `context.skips.clear()` `context.skips.contains()` etc. |
| context.next()  | void                | Call the next handler.                                                                                                                                                                      |
| context.stop()  | void                | Stop execute any following handlers. A bit like the the stop in process builders.                                                                                                           |

### 8.3 Triggers.Props

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

| Method                                                                                                                                                                                                     | Type       | Description                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------- |
| - `isChanged(SObjectField field1)`                                                                                                                                                                         | Boolean    | Check if any record has a field changed during an update.                                                                 |
| - `isChangedAny(SObjectField field1, SObjectField field2)`<br>- `isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3)`<br>- `isChangedAny(List<SObjectField> fields)`               | Boolean    | Check if any record has multiple fields changed during an update. Return `true` if any specified field is changed.        |
| - `isChangedAll(SObjectField field1, SObjectField field2)`<br>- `isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3)`<br>- `isChangedAll(List<SObjectField> fields)`               | Boolean    | Check if any record has multiple fields changed during an update. Return `true` only if all specified fields are changed. |
| - `filterChanged(SObjectField field1)`                                                                                                                                                                     | List\<Id\> | Filter IDs of records have a field changed during an update.                                                              |
| - `filterChangedAny(SObjectField field1, SObjectField field2)`<br/>- `filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3)`<br/>- `filterChangedAny(List<SObjectField> fields)` | List\<Id\> | Filter IDs of records have multiple fields changed during an update. Return IDs if any specified field is changed.        |
| - `filterChangedAll(SObjectField field1, SObjectField field2)`<br/>- `filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3)`<br/>- `filterChangedAll(List<SObjectField> fields)` | List\<Id\> | Filter IDs of records have multiple fields changed during an update. Return IDs only if all specified fields are changed. |

## 9. License

BSD 3-Clause License
