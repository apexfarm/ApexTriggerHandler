# Apex Trigger Handler

![](https://img.shields.io/badge/version-1.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E100%25-brightgreen.svg)

This is another library to implement the Apex trigger handler design pattern. There are already many handler libraries out there, this one has some different approaches or advantanges.

```c#
// 1. Use interfaces instead of a base class to extend a custom handler. With interface 
// approach we can declare only the needed interfaces explicitly, which is much cleaner 
// and clearer.
class MyAccountHandler implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
  
    // 2. There is a "when" stage before any execution of the handlers. This gives 
    // developers a chance to turn on and off the handlers according to configurations
    // at run time. 
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
        // 4. All properties on Trigger have been exposed to triggerProp. We can 
        // avoid direct reference of Trigger.old and Trigger.new, instead use
        // context.triggerProp.oldList and context.triggerProp.newList.
        if (context.triggerProp.isUpdate) {
          // 5. Use state if there are query or computation results need to be passed
          // to the next handlers.
        	if (context.state.get('counter') == null) {
              context.state.put('counter', 0);
          }
          
          // 6. Call next() to begin execution of the rest of the handlers.
          context.next();
          
          // 7. When the rest of the handlers finished execution, some following up 
          // logics can be performed here.
          Integer counter = (Integer)context.state.get('counter');
        }
    }
}
```



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



