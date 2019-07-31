# Apex Trigger Handler

![](https://img.shields.io/badge/version-1.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

There are already many trigger handler libraries out there, but this one has some different approaches or advantanges such as state sharing, built in helper methods etc.. Just one class `Triggers.cls` with its corresponding test class `TriggersTest.cls`, and its minimal and simple.

## Features

1. In favour of interface implementation over the base class extension.
2. Enable sharing state across different handlers easily.
3. Built-in helper to perform operations with Trigger.new or Trigger.old.

## Usage

To create a trigger handler, you will need to create a class that implements the `Triggers.Handler` interface `when` method, and the corresponding trigger event methods, such as the `Triggers.BeforeUpdate` interface `beforeUpdate` method. 

```java
class MyAccountHandler implements Triggers.Handler, Triggers.BeforeUpdate { 
    public Boolean when(Triggers.Context context, Triggers.Helper helper) {
        return true;
    }
  
    public void beforeUpdate(Triggers.Context context, Triggers.Helper helper) {
        // do stuff
    }
}
```

#### Trigger Handler Example

```java
// 1. Use interfaces instead of a base class to extend a custom handler. With interface 
// approach we can declare only the needed interfaces explicitly, which is much cleaner 
// and clearer.
class MyAccountHandler implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
  
    // 2. There is a "when" stage before any handler execution. This gives 
    // developers chances to turn on and off the handlers according to 
    // configurations at run time. 
    public Boolean when(Triggers.Context context, Triggers.Helper helper) {
        return Triggers.WHEN_ALWAYS;
        // 3. There are also helper methods to check if certain fields have changes
        // return helper.isChangedAny(Account.Name, Account.Description);
        // return helper.isChangedAll(Account.Name, Account.Description);
    }

    public void beforeUpdate(Triggers.Context context, Triggers.Helper helper) {
        then(context, helper);
    }
  
    public void afterUpdate(Triggers.Context context, Triggers.Helper helper) {
        then(context, helper);
    }
  
    private void then(Triggers.Context context, Triggers.Helper helper) {
        // 4. All properties on Trigger have been exposed to context.triggerProp. 
      	// Direct reference of Trigger.old and Trigger.new can be avoided, 
        // instead use context.triggerProp.oldList and context.triggerProp.newList.
        if (context.triggerProp.isUpdate) {
          // 5. Use context.state to pass query or computation results down to all 
          // following handlers within the current trigger context, i.e. before update.
          if (context.state.get('counter') == null) {
              context.state.put('counter', 0);
          }
          
          // 6. Call context.next() to execute the next handler. This is required for
          // every following handlers if need to wrap up something after all the 
          // following handlers finish. Otherwise it is optional to call.
          context.next();
          // When the next handler finishes execution, some following up 
          // logics can be performed here.
          
          // 7. If context.stop() is called before context.next(), any following 
          // handlers won't be executed, just like the stop in process builder.
          context.stop();
        }
    }
}
```

### Trigger Example

As you may noticed, why we are creating same handlers for different trigger events, i.e. before update and after update? This is because handlers may need to execute in different orders for different trigger events.

```java
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .beforeUpdate()
            .bind(new MyAccountHandler())
            .bind(new AnotherAccountHandler()
        .afterUpdate()
            .bind(new AnotherAccountHandler()
            .bind(new MyAccountHandler())
        .execute();
}
```

## APIs

### Trigger Handler Interfaces

| Interface               | Method to Implement                                          |
| ----------------------- | ------------------------------------------------------------ |
| Triggers.Handler        | `Boolean when(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.BeforeInsert   | `void beforeInsert(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.AfterInsert    | `void afterInsert(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.BeforeUpdate   | `void beforeUpdate(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.AfterUpdate    | `void afterUpdate(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.BeforeDelete   | `void beforeDelete(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.AfterDelete    | `void afterDelete(Triggers.Context context, Triggers.Helper helper);` |
| Triggers.BeforeUndelete | `void afterUndelete(Triggers.Context context, Triggers.Helper helper);` |

### Trigger Context

| Property/Method     | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| context.triggerProp | A read-only instance exposes every properties on `Trigger` context, i.e. <br/>   - `Trigger.new` => `context.triggerProp.newList`<br/>   - `Trigger.old` => `context.triggerProp.oldList` |
| context.state       | A `Map<String, Object>` provided for developers to pass any value down to other handlers. |
| context.next()      | Call the next handler.                                       |
| context.stop()      | Stop execute any following handlers. A bit like the the stop in process builders. |

### Trigger Helper

| Method                  | Return Type | Description                                                  |
| ----------------------- | ----------- | ------------------------------------------------------------ |
| helper.isChanged        | Boolean     | Check if any record has a field changed during an update.    |
| helper.isChangedAny     | Boolean     | Check if any record has multiple fields changed during an update. Return true if any specified field is changed. |
| helper.isChangedAll     | Boolean     | Check if any record has multiple fields changed during an update. Return true only if all specified fields are changed. |
| helper.filterChanged    | Set\<Id\>   | Filter IDs of records have a field changed during an update. |
| helper.filterChangedAny | Set\<Id\>   | Filter IDs of records have mulantiple fields changed during an update. Return IDs if any specified field is changed. |
| helper.filterChangedAll | Set\<Id\>   | Filter IDs of records have mulantiple fields changed during an update. Return IDs only if all specified fields are changed. |

## License

MIT License