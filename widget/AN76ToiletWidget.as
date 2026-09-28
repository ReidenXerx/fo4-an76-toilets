package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.getQualifiedClassName;
   import hudframework.IHUDWidget;

   // The toilet icon, joined to the game's own status-effect row (hunger, thirst, sleep... and AN76's).
   //
   // The HUD keeps those icons as HUDActiveEffectClip children of HUDActiveEffectsWidget.ClipHolderInternal,
   // up to 8, laid out by the engine (vanilla) or by FallUI's layout options (direction, spacing). Their
   // positions are read every frame, never assumed: this icon takes the slot after the last visible one,
   // at that row's size. On a HUD without that row it stays where HUDFramework put it.
   //
   // Frames: 1 hidden, 2 yellow, 3 orange, 4 red (drawn on the timeline by tools/make_widget.py).
   // Messages from Papyrus: 1 = stage (params[0]); 2 = nudge x, nudge y, size multiplier.
   public class AN76ToiletWidget extends MovieClip implements IHUDWidget
   {
      private static const ICON_PX:Number = 40;

      private var _holder:DisplayObjectContainer = null;
      private var _widget:Object = null;
      private var _nudgeX:Number = 0;
      private var _nudgeY:Number = 0;
      private var _size:Number = 1;
      private var _searchCooldown:int = 0;

      public function AN76ToiletWidget()
      {
         super();
         stop();
         addEventListener(Event.ENTER_FRAME, this.follow);
      }

      public function processMessage(command:String, params:Array) : void
      {
         var c:int = int(command);
         if(c == 1)
         {
            gotoAndStop(int(params[0]) + 1);
         }
         else if(c == 2)
         {
            _nudgeX = Number(params[0]);
            _nudgeY = Number(params[1]);
            _size = Number(params[2]) > 0 ? Number(params[2]) : 1;
         }
      }

      private function findRow(node:DisplayObjectContainer, depth:int) : DisplayObjectContainer
      {
         var i:int = 0;
         while(i < node.numChildren)
         {
            var child:DisplayObject = node.getChildAt(i);
            if(getQualifiedClassName(child) == "HUDActiveEffectsWidget")
            {
               try
               {
                  _widget = child;
                  return Object(child).ClipHolderInternal as DisplayObjectContainer;
               }
               catch(e:Error)
               {
               }
            }
            if(depth < 10 && child is DisplayObjectContainer)
            {
               var found:DisplayObjectContainer = this.findRow(child as DisplayObjectContainer, depth + 1);
               if(found)
               {
                  return found;
               }
            }
            i++;
         }
         return null;
      }

      private function follow(e:Event) : void
      {
         if(currentFrame <= 1 || stage == null || parent == null)
         {
            return;
         }
         if(_holder == null || _holder.stage == null)
         {
            if(_searchCooldown > 0)
            {
               _searchCooldown--;
               return;
            }
            _holder = this.findRow(stage, 0);
            if(_holder == null)
            {
               // No status row on this HUD: stay where HUDFramework placed the widget, at the MCM size.
               x = y = 0;
               scaleX = scaleY = _size;
               _searchCooldown = 120;
               return;
            }
         }
         var n:int = _holder.numChildren;
         if(n == 0)
         {
            return;
         }
         var first:DisplayObject = _holder.getChildAt(0);
         var step:Point;
         if(n > 1)
         {
            var second:DisplayObject = _holder.getChildAt(1);
            step = new Point(second.x - first.x,second.y - first.y);
         }
         else
         {
            step = new Point(-26,0);
         }
         var last:int = -1;
         var visibleClip:DisplayObject = null;
         var i:int = 0;
         while(i < n)
         {
            if(_holder.getChildAt(i).visible)
            {
               last = i;
               visibleClip = _holder.getChildAt(i);
            }
            i++;
         }
         // Where a clip's drawn icon sits relative to its origin, and how big it is on screen: from a
         // visible clip when there is one, else the row's nominal size.
         var rowScale:Number = _holder.transform.concatenatedMatrix.a;
         var shown:Number = 23 * rowScale;
         var offset:Point = new Point(0,0);
         if(visibleClip != null)
         {
            var bounds:Rectangle = visibleClip.getBounds(stage);
            var origin:Point = _holder.localToGlobal(new Point(visibleClip.x,visibleClip.y));
            offset = new Point(bounds.x - origin.x,bounds.y - origin.y);
            shown = bounds.height;
         }
         var slot:Point = _holder.localToGlobal(new Point(first.x + step.x * (last + 1),first.y + step.y * (last + 1)));
         slot.x += offset.x + _nudgeX;
         slot.y += offset.y + _nudgeY;
         var local:Point = parent.globalToLocal(slot);
         x = local.x;
         y = local.y;
         var parentScale:Number = parent.transform.concatenatedMatrix.a;
         if(parentScale == 0)
         {
            parentScale = 1;
         }
         scaleX = scaleY = shown * _size / (ICON_PX * parentScale);
      }
   }
}
