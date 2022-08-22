package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.utils.EntityCache;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Invoker;
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
import net.minecraft.sound.SoundEvent;

import net.fabricmc.example.handlers.ActionHandler;;
import net.fabricmc.example.handlers.StatusHandler;
import java.util.HashSet;
import java.util.UUID;

// counter-attack attacker on damage taken
@Mixin(LivingEntity.class)
public class MixinLivingEntity {
    // it works!
    //    @Inject(method = "<init>(Lnet/minecraft/entity/EntityType;Lnet/minecraft/world/World;)V", at = @At("RETURN"))
    //    private void init(EntityType type, World world, CallbackInfo ci) {
    //        if ( ExampleMod.LOGGER != null ) {
    //            ExampleMod.LOGGER.info("[d] " + type.toString());
    //        }
    //    }

//    private static HashSet<String> knownEntities = new HashSet<String>();

//    // works
//    @Inject(method = "swingHand(Lnet/minecraft/util/Hand;)V", at = @At("HEAD"))
//    private void swingHand(Hand hand, CallbackInfo ci) {
//        if (!(((Object)this) instanceof PlayerEntity)) {
////            ExampleMod.LOGGER.info("[d] " + this.toString() + ": swingHand");
//            LivingEntity e = (LivingEntity)(Object)this;
////            String id = EntityType.getId(e.getType()).toString();
////            if ( !knownEntities.contains(id) ) {
////                knownEntities.add(id);
////                StatusHandler.logEntity(e);
////            }
//            if ( ActionHandler.log.length() > 10*1024*1024 ) {
//                ActionHandler.log = new String();
//            }
//            ActionHandler.log = ActionHandler.log + StatusHandler.serializeEntity(e).toString() + "\n";
//        }
//    }

    // works
    @Inject(method = "onDeath(Lnet/minecraft/entity/damage/DamageSource;)V", at = @At("HEAD"))
    private void onDeath(DamageSource ds, CallbackInfo ci) {
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + this.toString() + ": onDeath from " + ds.getName());
//        }
    }

    @Inject(method = "canHit()Z", at = @At("HEAD"), cancellable = true)
    private void canHit(CallbackInfoReturnable<Boolean> cir) {
        UUID uuid = ((Entity)(Object)this).getUuid();
        long hide = EntityCache.getExtra(uuid, EntityCache.HIDE_ENTITY);
        if ( hide != 0 )
            cir.setReturnValue(false);
    }


    @Inject(method = "animateDamage()V", at = @At("HEAD"))
    private void animateDamage(CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ) {
            ExampleMod.LOGGER.info("[d] " + this.toString() + ": animateDamage");
        }
    }

    @Inject(method = "applyDamage(Lnet/minecraft/entity/damage/DamageSource;F)V", at = @At("HEAD"))
    private void applyDamage(DamageSource source, float amount, CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ) {
            ExampleMod.LOGGER.info("[d] " + this.toString() + ": applyDamage " + amount);
        }
    }

//  works, but strange
//    @Inject(method = "getAttacking()Lnet/minecraft/entity/LivingEntity;", at = @At("HEAD"))
//    private void getAttacking(CallbackInfoReturnable<LivingEntity> cir) {
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + this.toString() + ": getAttacking");
//        }
//    }

    @Inject(method = "attackLivingEntity(Lnet/minecraft/entity/LivingEntity;)V", at = @At("HEAD"))
    private void attackLivingEntity(LivingEntity target, CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ) {
            ExampleMod.LOGGER.info("[d] " + this.toString() + ": attackLivingEntity");
        }
    }

    // causes exceptions!
//    @Inject(method = "onAttacking(Lnet/minecraft/entity/Entity;)V", at = @At("HEAD"))
//    private void onAttacking(Entity entity, CallbackInfo ci) {
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] " + this.toString() + ": onAttacking");
//        }
//    }

    @Inject(method = "playHurtSound(Lnet/minecraft/entity/damage/DamageSource;)V", at = @At("HEAD"))
    private void playHurtSound(DamageSource source, CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ) {
            ExampleMod.LOGGER.info("[d] " + this.toString() + ": playHurtSound");
        }
    }

    @Inject(method = "getHurtSound(Lnet/minecraft/entity/damage/DamageSource;)Lnet/minecraft/sound/SoundEvent;", at = @At("HEAD"))
    private void playHurtSound(DamageSource source, CallbackInfoReturnable<SoundEvent> cir) {
        if ( ExampleMod.LOGGER != null ) {
            ExampleMod.LOGGER.info("[d] " + this.toString() + ": getHurtSound");
        }
    }
}
