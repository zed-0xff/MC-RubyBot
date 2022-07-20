package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.handlers.StatusHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(net.minecraft.client.network.ClientPlayNetworkHandler.class)
public abstract class MixinClientPlayNetworkHandler {
    @Inject(method = "onGameMessage", at = @At("RETURN"))
    private void onGameMessage(net.minecraft.network.packet.s2c.play.GameMessageS2CPacket packet, CallbackInfo ci)
    {
        String msg = packet.content().getString();
        if ( ExampleMod.LOGGER != null && packet.typeId() != 2 && packet.typeId() != 1 ) {
            ExampleMod.LOGGER.info("[d] onGameMessage type=" + packet.typeId() + " : " + msg);
        }
        // TODO: filter type=1 (chat)
        StatusHandler.handleMessage(packet.typeId(), msg);
    }
}
