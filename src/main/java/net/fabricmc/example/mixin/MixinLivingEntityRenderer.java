package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.world.World;

import net.minecraft.client.render.entity.LivingEntityRenderer;
import net.minecraft.client.render.entity.model.EntityModel;
import net.minecraft.client.render.entity.feature.FeatureRenderer;

@Mixin(LivingEntityRenderer.class)
public abstract class MixinLivingEntityRenderer<T extends LivingEntity,M extends EntityModel<T>> {
    // works only on start of client?
//    @Inject(method = "addFeature(Lnet/minecraft/client/render/entity/feature/FeatureRenderer;)Z", at = @At("HEAD"))
//    void foo(FeatureRenderer<T,M> feature, CallbackInfoReturnable<Boolean> cir){
//        ExampleMod.LOGGER.info("[d] " + this.toString() + ": addFeature " + feature.toString());
//    }
//
//    // works
//    @Inject(method = "getHandSwingProgress(Lnet/minecraft/entity/LivingEntity;F)F", at = @At("HEAD"))
//    void bar(T entity, float tickDelta, CallbackInfoReturnable<Float> cir){
//        ExampleMod.LOGGER.info("[d] getHandSwingProgress");
//    }

}
