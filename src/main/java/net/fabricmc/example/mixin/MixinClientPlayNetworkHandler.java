package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.handlers.ActionHandler;
import net.fabricmc.example.handlers.StatusHandler;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.util.Formatting;
import net.minecraft.text.Text;
import com.google.gson.*;

@Mixin(net.minecraft.client.network.ClientPlayNetworkHandler.class)
public abstract class MixinClientPlayNetworkHandler {

    private static JsonElement _serialize(Text msg) {
        JsonObject obj = new JsonObject();
        JsonArray events = new JsonArray();
        obj.addProperty("message", Formatting.strip(msg.getString()));
        for (Text sibling : msg.getSiblings()) {
            net.minecraft.text.ClickEvent e = sibling.getStyle().getClickEvent();
            if ( e != null ) events.add(e.getValue());
        }
        if( events.size() != 0 ) {
            obj.add("events", events);
        }
        return obj;
    }
    
    private static int lastHashCode = 0;

    @Inject(method = "onGameMessage", at = @At("HEAD"), cancellable = true)
    private void onGameMessage(net.minecraft.network.packet.s2c.play.GameMessageS2CPacket packet, CallbackInfo ci)
    {
        String msg = packet.content().getString();
        StatusHandler.handleMessage(packet.overlay(), msg);
        if ( !packet.overlay() ) {
            // HACK
            if (packet.hashCode() != lastHashCode) {
                lastHashCode = packet.hashCode();
                ActionHandler.messageLog.add(_serialize(packet.content()));
            }
        }
        if ( ActionHandler.shouldHideMessage(packet.overlay(), msg)) {
            ci.cancel();
        }
    }

    @Inject(method = "onBlockUpdate", at = @At("HEAD"))
    private void markChunkChangedBlockChange(net.minecraft.network.packet.s2c.play.BlockUpdateS2CPacket packet, CallbackInfo ci)
    {
        ActionHandler.onBlockChange(packet.getPos(), packet.getState());
    }
}
