package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.world.World;
import net.minecraft.util.Hand;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.entity.damage.DamageTracker;

// counter-attack attacker on damage taken
@Mixin(DamageTracker.class)
public class MixinDamageTracker {
    // does not work :(
//    @Inject(method = "onDamage(Lnet/minecraft/entity/damage/DamageSource;FF)V", at = @At("HEAD"))
//    void foo(DamageSource source, float originalHealth, float damage, CallbackInfo ci){
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + this.toString() + ": onDamage " + source.toString());
//        }
//    }
}
