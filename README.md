# Apex Trigger Handler

![](https://img.shields.io/badge/version-1.2-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E95%25-brightgreen.svg)

There are already many trigger handler libraries out there, but this one has some different approaches or advantages such as state sharing, built in helper methods etc.

### Features

1. Built-in helpers to perform common operations on trigger properties, such as detect field changes.
2. Control flow of handler execution with `context.next()`, `context.stop()`, and `context.skips`.
3. Optionally register and control handlers with custom metadata type settings.

### Package ApexTriggerHandler

This package is the minimal installation which only includes two classes `Triggers.cls` and `TriggersTest.cls`.

| Environment           | Installation Link                                                                                                                                         | Version |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007Cfg6AAC"><img src="docs/images/deploy-button.png"></a> | ver 1.2 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007Cfg6AAC"><img src="docs/images/deploy-button.png"></a>  | ver 1.2 |

### Package ApexTriggerHandlerExt

This package can be optionally installed to extend a new feature ([custom metadata type settings](#12-bind-with-handler-settings)) for the above one. It introduces additional but only one SOQL query to a custom metadata type. If your system already reaches some governor limit around SOQL queries, can consider deploy this one later. **Note**: The above package is required to be installed before this one.

| Environment           | Installation Link                                                                                                                                         | Version |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgBAAS"><img src="docs/images/deploy-button.png"></a> | ver 1.2 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgBAAS"><img src="docs/images/deploy-button.png"></a>  | ver 1.2 |

---

### v1.2 Release Notes

- Support custom metadata type settings to register trigger handlers. ([jump to section](#12-bind-with-handler-settings))

---

## Table of Contents

- [1. Trigger](#1-trigger)
  * [1.1 Bind with Handler Instances](#11-bind-with-handler-instances)
  * [1.2 Bind with Handler Settings](#12-bind-with-handler-settings)
  * [1.3 Bind with DI Framework](#13-bind-with-di-framework)
- [2. Trigger Handler](#2-trigger-handler)
  * [2.1 Create Handlers](#21-create-handlers)
  * [2.2 Skip Handlers](#22-skip-handlers)
- [3. Tests](#3-tests)
  * [3.1 Test with Mockup Data](#31-test-with-mockup-data)
  * [3.2 Test with Mockup Library](#32-test-with-mockup-library)
- [4. APIs](#4-apis)
  * [4.1 Trigger Handler Interfaces](#41-trigger-handler-interfaces)
  * [4.2 Triggers.Context](#42-triggerscontext)
  * [4.3 Triggers.Props](#43-triggersprops)
- [5. License](#5-license)

## 1. Trigger

### 1.1 Bind with Handler Instances

This is an example about how handlers can be registered in triggers. As you have noticed, we are creating same handlers for different trigger events. This is because handlers may need to execute in different orders for different trigger events, we need to provide developers great controls over the order of executions.

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

### 1.2 Bind with Handler Settings

This feature is only available when `ApexTriggerHandlerExt` package is installed, or its metadata is manually deployed. Here are some sample records of `Apex_Trigger_Handler_Setting__mdt`, which can provide fine-grained control of trigger handler behaviors at runtime, such as:

1. To register trigger handlers for a particular sObject trigger event (`SObject__c`, `Trigger_Event__c`, `Handler_Class__c`).
2. To activate or deactivate trigger handlers (`Active__c`).
3. To reorder trigger handlers (`Execution_Order__c`).
4. To optionally group trigger handlers with tags (`Tag__c`).

| SObject\_\_c | Trigger_Event\_\_c | Handler_Class\_\_c     | Execution_Order\_\_c | Tag\_\_c | Active\_\_c |
| ------------ | ------------------ | ---------------------- | -------------------- | -------- | ----------- |
| Account      | BEFORE_UPDATE      | AccountTriggerHandler1 | 1                    | tag1     | TRUE        |
| Account      | BEFORE_UPDATE      | AccountTriggerHandler2 | 2                    |          | TRUE        |
| Account      | BEFORE_UPDATE      | AccountTriggerHandler3 | 3                    |          | **FALSE**   |
| Account      | AFTER_UPDATE       | AccountTriggerHandler4 | 1                    | tag1     | TRUE        |
| Account      | AFTER_UPDATE       | AccountTriggerHandler5 | 2                    | tag2     | TRUE        |
| Account      | AFTER_UPDATE       | AccountTriggerHandler6 | 3                    | tag2     | TRUE        |

Two additional APIs are provided to load the handlers from the above settings, `load()` and `load(tag)`. Their usages are explained in the following comments.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .beforeUpdate()
            .bind(new MyAccountHandler())
            .load()       // load all active handlers under Account BEFORE_UPDATE
                          // - AccountTriggerHandler1
                          // - AccountTriggerHandler2
            .bind(new AnotherAccountHandler())
        .afterUpdate()
            .bind(new AnotherAccountHandler())
            .load('tag1') // load all active handlers with 'tag1' under Account AFTER_UPDATE
                          // - AccountTriggerHandler4
            .bind(new MyAccountHandler())
            .load('tag2') // load all active handlers with 'tag2' under Account AFTER_UPDATE
                          // - AccountTriggerHandler5
                          // - AccountTriggerHandler6
        .execute();
}
```

### 1.3 Bind with DI Framework

The following demo is using [Apex DI](https://github.com/apexfarm/ApexDI) as a dependency injection (DI) framework.

```java
trigger AccountTrigger on Account (before update, after update) {
    // reference interfaces and decouple trigger from implementations
    DI.Module salesModule = DI.getModule(SalesModule.class);
    Triggers.prepare()
        .beforeUpdate()
            .bind((Triggers.Handler) salesModule.getService(IMyAccountHandler.class))
            .bind((Triggers.Handler) salesModule.getService(IAnotherAccountHandler.class))
        .afterUpdate()
            .bind((Triggers.Handler) salesModule.getService(IAnotherAccountHandler.class))
            .bind((Triggers.Handler) salesModule.getService(IMyAccountHandler.class))
        .execute();
}

public class SalesModule extends DI.Module {
    // register handler implementation against interfaces
    protected overried void configure(DI.ServiceCollection services) {
        services.addTransient('IMyAccountHandler', 'MyAccountHandler');
        services.addTransient('IAnotherAccountHandler', 'AnotherAccountHandler');
    }
}

public class IMyAccountHandler extends Triggers.Handler {}
public class MyAccountHandler implements IMyAccountHandler, Triggers.BeforeUpdate, Triggers.AfterUpdate {}

public class IAnotherAccountHandler extends Triggers.Handler {}
public class AnotherAccountHandler implements IAnotherAccountHandler, Triggers.BeforeUpdate, Triggers.AfterUpdate {}
```

## 2. Trigger Handler

### 2.1 Create Handlers

To create a trigger handler, you will need to create a class that implements the `Triggers.Handler` interface and its `criteria` method. Please check the comments below for detailed explanations and tricks to customize a trigger handler.

```java
// 1. Use interfaces instead of a base class to extend a custom handler. With interface
// approach we can declare only the needed interfaces explicitly, which is much cleaner
// and clearer.
public class MyAccountHandler implements Triggers.Handler,
                                         Triggers.BeforeUpdate,
                                         Triggers.AfterUpdate {

    // 2. There is a "criteria" stage before any handler execution. This gives
    // developers opportunities to turn on and off the handlers according to
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
      	// Direct reference of Trigger.old and Trigger.new should be avoided,
        // instead use context.props.oldList and context.props.newList.
        if (context.props.isUpdate) {

            // 5. Use context.state to pass query or computation results down to all
            // following handlers within the current trigger context, i.e. before update.
            // Before update and after update are considered as differenet contexts.
            Integer counter = (Integer) context.state.get('counter');
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

### 2.2 Skip Handlers

Global static variable `Triggers.skips` references the same `context.skips`, so you can use it to skip handlers outside of the handler contexts. For example, when you want to skip a trigger handler in a batch class:

```java
global class AccountUpdateBatch implements Database.Batchable<SObject> {
    ...
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Triggers.skips.add(MyAccountHandler.class);
        // Update accounts...
        Triggers.skips.remove(MyAccountHandler.class);
    }
    ...
}
```

## 3. Tests

### 3.1 Test with Mockup Data

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

### 3.2 Test with Mockup Library

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

## 4. APIs

### 4.1 Trigger Handler Interfaces

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

### 4.2 Triggers.Context

| Property/Method | Type                | Description                                                                                                                                                                                 |
| --------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| context.props   | Triggers.Props      | All properties on Trigger are exposed by this class. In addition there are frequently used helper methods and a convinient sObjectType property, in case reflection is needed .             |
| context.state   | Map<Object, Object> | A map provided for developers to pass any value down to other handlers.                                                                                                                     |
| context.skips   | Triggers.Skips      | A set to store handlers to be skipped. Call the following methods to manage skips: `context.skips.add()`, `context.skips.remove()`, `context.skips.clear()` `context.skips.contains()` etc. |
| context.next()  | void                | Call the next handler.                                                                                                                                                                      |
| context.stop()  | void                | Stop execute any following handlers. A bit like the the stop in process builders.                                                                                                           |

### 4.3 Triggers.Props

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

## 5. License

BSD 3-Clause License
