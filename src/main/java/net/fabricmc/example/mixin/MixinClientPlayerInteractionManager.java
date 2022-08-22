package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import net.fabricmc.example.utils.EntityCache;

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
//    @Inject(method = "interactItem(" +
//                     "Lnet/minecraft/entity/player/PlayerEntity;" +
//                     "Lnet/minecraft/util/Hand;" +
//                     ")Lnet/minecraft/util/ActionResult;",
//            at = @At("HEAD"),
//            cancellable = true
//            )
//    private void interactItem(PlayerEntity player, Hand hand, CallbackInfoReturnable<ActionResult> cir)
//    {
// works!
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + hand);
//            if ( player.getInventory().getStack(9).isEmpty() ) {
//                cir.setReturnValue(ActionResult.FAIL);
//            }
//        }
//    }

//    // not works o_O
//    @Inject(method = "interactEntity(" +
//                     "Lnet/minecraft/entity/player/PlayerEntity;" +
//                     "Lnet/minecraft/entity/Entity;" +
//                     "Lnet/minecraft/util/Hand;" +
//                     ")Lnet/minecraft/util/ActionResult;",
//            at = @At("HEAD"),
//            cancellable = true
//            )
//    private void interactEntity(PlayerEntity player, Entity entity, Hand hand, CallbackInfoReturnable<ActionResult> cir)
//    {
//            long hide = EntityCache.getExtra(entity.getUuid(), EntityCache.HIDE_ENTITY);
//            if ( ExampleMod.LOGGER != null ) {
//                ExampleMod.LOGGER.info("[d] interactEntity " + entity + ", hide=" + hide);
//            }
//            if ( hide == 1 ) {
//                cir.setReturnValue(ActionResult.PASS);
//            }
//    }
//
//    // not works either...
//    @Inject(method = "interactEntityAtLocation(" +
//                     "Lnet/minecraft/entity/player/PlayerEntity;" +
//                     "Lnet/minecraft/entity/Entity;" +
//                     "Lnet/minecraft/util/hit/EntityHitResult;" +
//                     "Lnet/minecraft/util/Hand;" +
//                     ")Lnet/minecraft/util/ActionResult;",
//            at = @At("HEAD"),
//            cancellable = true
//            )
//    private void interactEntityAtLocation(PlayerEntity player, Entity entity, EntityHitResult hitResult, Hand hand, CallbackInfoReturnable<ActionResult> cir)
//    {
//            long hide = EntityCache.getExtra(entity.getUuid(), EntityCache.HIDE_ENTITY);
//            if ( ExampleMod.LOGGER != null ) {
//                ExampleMod.LOGGER.info("[d] interactEntityAtLocation " + entity + ", hide=" + hide);
//            }
//            if ( hide == 1 ) {
//                // XXX TODO: check
//                cir.setReturnValue(ActionResult.PASS);
//            }
//    }
}
