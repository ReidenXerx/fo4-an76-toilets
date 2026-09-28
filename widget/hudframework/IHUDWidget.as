package hudframework
{
   // HUDFramework's widget interface (HUDFramework 1.0f). Declared here only so this widget compiles on
   // its own: loaded by HUDFramework, the name resolves to HUDFramework's own definition.
   public interface IHUDWidget
   {
      function processMessage(command:String, params:Array) : void;
   }
}
