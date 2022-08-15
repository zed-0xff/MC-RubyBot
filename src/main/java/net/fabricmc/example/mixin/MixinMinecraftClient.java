package net.fabricmc.example.mixin;

import net.fabricmc.example.utils.EntityCache;

import net.fabricmc.example.handlers.StatusHandler;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.world.ClientWorld;
import net.minecraft.entity.Entity;

@Mixin(MinecraftClient.class)
public abstract class MixinMinecraftClient
{
    @Inject(method = "joinWorld(Lnet/minecraft/client/world/ClientWorld;)V", at = @At("RETURN"))
    private void onLoadWorldPost(ClientWorld world, CallbackInfo ci) {
        if ( world != null ) {
            StatusHandler.locraw = null;
        }
    }

    // force MC to think it's always focused
    // otherwise automining stops working after any Screen (crafting/container)
    @Inject(method = "isWindowFocused()Z", at = @At("HEAD"), cancellable = true)
    private void isWindowFocused(CallbackInfoReturnable<Boolean> cir) {
        cir.setReturnValue(true);
    }

    @Inject(method = "hasOutline", at = @At("HEAD"), cancellable = true)
    private void outlineEntities(Entity entity, CallbackInfoReturnable<Boolean> ci) {
        Long color = EntityCache.getExtra(entity.getUuid());
        if ( color != null && color != 0 ) {
            ci.setReturnValue(true);
        }
    }
}
