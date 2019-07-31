# Apex Trigger Handler

![](https://img.shields.io/badge/version-1.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

This is another library to implement the Apex trigger handler design pattern. There are already many handler libraries out there, but this one has some different approaches or advantanges as explained in the following comments:

#### Trigger Handler Example

```c#
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
          
          // 6. Call context.next() to execute the next handler. This is optional, but
          // useful when need to wrap up something after the next handler finishes.
          context.next();
          
          // 7. When the next handler finishes execution, some following up 
          // logics can be performed here.
          Integer counter = (Integer)context.state.get('counter');
        }
    }
}
```

#### Trigger Example

```c#
trigger AccountTrigger on Account (before update, after update) {
    Triggers.prepare()
        .beforeUpdate()
            .bind(new MyAccountHandler())
         // .bind(new AnotherAccountHandler()
        .afterUpdate()
            .bind(new MyAccountHandler())
         // .bind(new AnotherAccountHandler()
        .execute();
}
```


