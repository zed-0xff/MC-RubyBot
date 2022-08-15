package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.network.ClientPlayerInteractionManager;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;

@Mixin(ClientPlayerInteractionManager.class)
public abstract class MixinClientPlayerInteractionManager {
    @Inject(method = "interactItem(" +
                     "Lnet/minecraft/entity/player/PlayerEntity;" +
                     "Lnet/minecraft/util/Hand;" +
                     ")Lnet/minecraft/util/ActionResult;",
            at = @At("HEAD"),
            cancellable = true
            )
    private void interactItem(PlayerEntity player, Hand hand, CallbackInfoReturnable<ActionResult> cir)
    {
// works!
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + hand);
//            if ( player.getInventory().getStack(9).isEmpty() ) {
//                cir.setReturnValue(ActionResult.FAIL);
//            }
//        }
    }
}
